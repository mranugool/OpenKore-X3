#########################################################################
#  OpenKore - Calculation of inter-map routes
#  Copyright (c) 2006 OpenKore Team
#
#  This software is open source, licensed under the GNU General Public
#  License, version 2.
#  Basically, this means that you're allowed to modify and distribute
#  this software. However, if you distribute modified versions, you MUST
#  also distribute the source code.
#  See http://www.gnu.org/licenses/gpl.html for the full license.
#########################################################################
# This task calculates a route between different maps. When the calculation
# is successfully completed, the result can be retrieved with
# $Task_CalcMapRoute->getRoute() or $Task_CalcMapRoute->getRouteString().
#
# Note that this task only performs calculation. The MapRoute task is
# responsible for actually walking from a map to another.
package Task::CalcMapRoute;

use strict;
use Time::HiRes qw(time);

use Modules 'register';
use Task;
use base qw(Task);
use Task::Route;
use Field;
use Globals qw(%config $field %portals_lut %portals_los %timeout $char %routeWeights);
use Translation qw(T TF);
use Log qw(debug);
use Utils qw(timeOut);
use Utils::Exceptions;

# Stage constants.
use constant {
	INITIALIZE => 1,
	CALCULATE_ROUTE => 2
};

# Error constants.
use enum qw(
	CANNOT_LOAD_FIELD
	CANNOT_CALCULATE_ROUTE
);


##
# Task::CalcMapRoute->new(options...)
#
# Create a new Task::CalcMapRoute object. The following options are allowed:
# `l
# - All options allowed for Task->new()
# - map (required) - The map you want to go to, for example "prontera".
# - x, y - The coordinate on the destination map you want to walk to. On some maps this is
#          important because they're split by a river. Depending on which side of the river
#          you want to be, the route may be different.
# - sourceMap - The map you're coming from. If not specified, the current map
#               (where the character is) is assumed.
# - sourceX and sourceY - The source position where you're coming from. If not specified,
#                         the character's current position is assumed.
# - budget - The maximum amount of money you want to spend on walking the route (Kapra
#            teleport service requires money).
# - maxTime - The maximum time to spend on calculation. If not specified,
#             $timeout{ai_route_calcRoute}{timeout} is assumed.
# `l`
sub new {
	my $class = shift;
	my %args = @_;
	my $self = $class->SUPER::new(@_);

	if (!$args{map}) {
		ArgumentException->throw(error => "Invalid arguments.");
	}

	$self->{source}{field} = defined($args{sourceMap}) ? Field->new(name => $args{sourceMap}) : $field;
	$self->{source}{map} = $self->{source}{field}->baseName;
	$self->{source}{x} = defined($args{sourceX}) ? $args{sourceX} : $char->{pos_to}{x};
	$self->{source}{y} = defined($args{sourceY}) ? $args{sourceY} : $char->{pos_to}{y};
	($self->{dest}{map}, undef) = Field::nameToBaseName(undef, $args{map}); # Hack to clean up InstanceID
	# $self->{dest}{map} = $args{map};
	$self->{dest}{pos}{x} = $args{x};
	$self->{dest}{pos}{y} = $args{y};
	if ($args{budget} ne '') {
		$self->{budget} = $args{budget};
	} elsif ($config{route_maxWarpFee} ne '') {
		if ($config{route_maxWarpFee} > $char->{zeny}) {
			$self->{budget} = $char->{zeny};
		} else {
			$self->{budget} = $config{route_maxWarpFee};
		}
	} else {
		$self->{budget} = $char->{zeny};
	}
	
	$self->{maxTime} = $args{maxTime} || $timeout{ai_route_calcRoute}{timeout};

	$self->{stage} = INITIALIZE;
	$self->{openlist} = {};
	$self->{closelist} = {};
	$self->{mapSolution} = [];
	$self->{solution} = [];
	$self->{dest}{field} = {};

	return $self;
}

# Overrided method.
sub iterate {
	my ($self) = @_;
	$self->SUPER::iterate();

	if ($self->{stage} == INITIALIZE) {
		my $openlist = $self->{openlist};
		my $closelist = $self->{closelist};
		eval {
			$self->{dest}{field} = new Field(name => $self->{dest}{map});
		};
		if (caught('FileNotFoundException', 'IOException')) {
			$self->setError(CANNOT_LOAD_FIELD, TF("Cannot load field '%s'.", $self->{dest}{map}));
			return;
		} elsif ($@) {
			die $@;
		}

		# Check whether destination is walkable from the starting point.
		if ($self->{source}{map} eq $self->{dest}{map}
		 && Task::Route->getRoute(undef, $self->{source}{field}, $self->{source}, $self->{dest}{pos}, 0)) {
			$self->{mapSolution} = [];
			$self->setDone();
			return;
		}

		# Initializes the openlist with portals walkable from the starting point.
		foreach my $portal (keys %portals_lut) {
			my $entry = $portals_lut{$portal};
			next if ($entry->{source}{map} ne $self->{source}{field}->baseName);
			my $ret = Task::Route->getRoute($self->{solution}, $self->{source}{field}, $self->{source}, $entry->{source});
			if ($ret) {
				for my $dest (grep { $entry->{dest}{$_}{enabled} } keys %{$entry->{dest}}) {
					my $penalty = int(($entry->{dest}{$dest}{steps} ne '') ? $routeWeights{NPC} : $routeWeights{PORTAL});
					$openlist->{"$portal=$dest"}{walk} = $penalty + scalar @{$self->{solution}};
					$openlist->{"$portal=$dest"}{zeny} = $entry->{dest}{$dest}{cost};
					$openlist->{"$portal=$dest"}{allow_ticket} = $entry->{dest}{$dest}{allow_ticket};
				}
			}
		}
		$self->{stage} = CALCULATE_ROUTE;
		debug "CalcMapRoute - initialized.\n", "route";

	} elsif ( $self->{stage} == CALCULATE_ROUTE ) {
		my $time = time;
		while ( !$self->{done} && (!$self->{maxTime} || !timeOut($time, $self->{maxTime})) ) {
			$self->searchStep();
		}
		if ($self->{found}) {
			delete $self->{openlist};
			delete $self->{solution};
			delete $self->{closelist};
			delete $self->{dest}{field};
			$self->setDone();
			debug "Map Solution Ready for traversal.\n", "route";
			debug sprintf("%s\n", $self->getRouteString()), "route";

		} elsif ($self->{done}) {
			my $destpos = "$self->{dest}{pos}{x},$self->{dest}{pos}{y}";
			$destpos = "($destpos)" if ($destpos ne "");
			$self->setError(CANNOT_CALCULATE_ROUTE, TF("Cannot calculate a route from %s (%d,%d) to %s %s",
				$self->{source}{field}->baseName, $self->{source}{x}, $self->{source}{y},
				$self->{dest}{map}, $destpos));
			debug "CalcMapRoute failed.\n", "route";
		}
	}
}

##
# Array<Hash>* $Task_CalcMapRoute->getRoute()
# Requires: $self->getStatus() == Task::DONE && !defined($self->getError())
#
# Return the calculated route.
sub getRoute {
	return $_[0]->{mapSolution};
}

##
# String $Task_CalcMapRoute->getRoute()
# Requires: $self->getStatus() == Task::DONE && !defined($self->getError())
#
# Return a string which describes the calculated route. This string has
# the following form: "payon -> pay_arche -> pay_dun00 -> pay_dun01"
sub getRouteString {
	my ($self) = @_;
	my @maps;
	foreach my $node (@{$self->{mapSolution}}) {
		push @maps, $node->{map};
	}
	push @maps, "$self->{dest}{map}";
	return join(' -> ', @maps);
}

sub searchStep {
	my ($self) = @_;
	my $openlist = $self->{openlist};
	my $closelist = $self->{closelist};

	unless ($openlist && %{$openlist}) {
		$self->{done} = 1;
		$self->{found} = '';
		return 0;
	}

	my $parent = (sort {$openlist->{$a}{walk} <=> $openlist->{$b}{walk}} keys %{$openlist})[0];
	debug "$parent, $openlist->{$parent}{walk}\n", "route/path";

	# Uncomment this if you want minimum MAP count. Otherwise use the above for minimum step count
	#foreach my $parent (keys %{$openlist})
	{
		my ($portal, $dest) = split /=/, $parent;
		if ($self->{budget} ne '' && !($char->inventory->getByNameID(7060) && $openlist->{$parent}{allow_ticket}) && ($openlist->{$parent}{zeny} > $self->{budget})) {
			# This link is too expensive
			# We should calculate the entire route cost
			delete $openlist->{$parent};
			next;
		} else {
			# MOVE this entry into the CLOSELIST
			$closelist->{$parent}{walk}   = $openlist->{$parent}{walk};
			$closelist->{$parent}{zeny}  = $openlist->{$parent}{zeny};
			$closelist->{$parent}{allow_ticket}  = $openlist->{$parent}{allow_ticket};
			$closelist->{$parent}{parent} = $openlist->{$parent}{parent};
			# Then delete in from OPENLIST
			delete $openlist->{$parent};
		}

		if ($portals_lut{$portal}{dest}{$dest}{map} eq $self->{dest}{map}) {
			if ($self->{dest}{pos}{x} eq '' && $self->{dest}{pos}{y} eq '') {
				$self->{found} = $parent;
				$self->{done} = 1;
				$self->{mapSolution} = [];
				my $this = $self->{found};
				while ($this) {
					my %arg;
					$arg{portal} = $this;
					my ($from, $to) = split /=/, $this;
					($arg{map}, $arg{pos}{x}, $arg{pos}{y}) = split / /, $from;
					($arg{dest_map}, $arg{dest_pos}{x}, $arg{dest_pos}{y}) = split(' ', $to);
					$arg{walk} = $closelist->{$this}{walk};
					$arg{zeny} = $closelist->{$this}{zeny};
					$arg{allow_ticket} = $closelist->{$this}{allow_ticket};
					$arg{steps} = $portals_lut{$from}{dest}{$to}{steps};

					unshift @{$self->{mapSolution}}, \%arg;
					$this = $closelist->{$this}{parent};
				}
				return;

			} elsif ( Task::Route->getRoute($self->{solution}, $self->{dest}{field}, $portals_lut{$portal}{dest}{$dest}, $self->{dest}{pos}) ) {
				my $walk = "$self->{dest}{map} $self->{dest}{pos}{x} $self->{dest}{pos}{y}=$self->{dest}{map} $self->{dest}{pos}{x} $self->{dest}{pos}{y}";
				$closelist->{$walk}{walk} = scalar @{$self->{solution}} + $closelist->{$parent}{$dest}{walk};
				$closelist->{$walk}{parent} = $parent;
				$closelist->{$walk}{zeny} = $closelist->{$parent}{zeny};
				$closelist->{$walk}{allow_ticket} = $closelist->{$parent}{allow_ticket};
				$self->{found} = $walk;
				$self->{done} = 1;
				$self->{mapSolution} = [];
				my $this = $self->{found};
				while ($this) {
					my %arg;
					$arg{portal} = $this;
					my ($from, $to) = split /=/, $this;
					($arg{map}, $arg{pos}{x}, $arg{pos}{y}) = split / /, $from;
					$arg{walk} = $closelist->{$this}{walk};
					$arg{zeny} = $closelist->{$this}{zeny};
					$arg{allow_ticket} = $closelist->{$this}{allow_ticket};
					$arg{steps} = $portals_lut{$from}{dest}{$to}{steps};

					unshift @{$self->{mapSolution}}, \%arg;
					$this = $closelist->{$this}{parent};
				}
				return;
			}
		}

		# Get all children of each openlist.
		foreach my $child (keys %{$portals_los{$dest}}) {
			next unless $portals_los{$dest}{$child};
			foreach my $subchild (grep { $portals_lut{$child}{dest}{$_}{enabled} } keys %{$portals_lut{$child}{dest}}) {
				my $destID = $subchild;
				my $mapName = $portals_lut{$child}{source}{map};
				#############################################################
				my $penalty = int($routeWeights{lc($mapName)}) +
					int(($portals_lut{$child}{dest}{$subchild}{steps} ne '') ? $routeWeights{NPC} : $routeWeights{PORTAL});
				my $thisWalk = $penalty + $closelist->{$parent}{walk} + $portals_los{$dest}{$child};
				if (!exists $closelist->{"$child=$subchild"}) {
					if ( !exists $openlist->{"$child=$subchild"} || $openlist->{"$child=$subchild"}{walk} > $thisWalk ) {
						$openlist->{"$child=$subchild"}{parent} = $parent;
						$openlist->{"$child=$subchild"}{walk} = $thisWalk;
						$openlist->{"$child=$subchild"}{zeny} = $closelist->{$parent}{zeny} + $portals_lut{$child}{dest}{$subchild}{cost};
						$openlist->{"$child=$subchild"}{allow_ticket} = $closelist->{$parent}{allow_ticket};
					}
				}
			}
		}
	}
}

1;