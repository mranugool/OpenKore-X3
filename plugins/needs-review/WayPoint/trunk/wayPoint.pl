# WayPoint v.3
#
# How to use:
# You can type:
# wp <x> <y> [<map name>]	to the coordinates on a map
# wp [<map name>] <x> <y>		to the coordinates on a map
# wp <map name>				to map
# wp <portal#>				to portal

package WayPoint;

use strict;
use Log qw(message error);
use Translation qw(T TF);
use Globals;
use Commands;
use AI qw(ai_route);

Plugins::register('WayPoint', 'lockMap WayPoint', \&Unload, \&Reload);

# Register command 'waypoint' hook
my $cmdHook = Commands::register( ['wp' , 'waypoint' , \&cmdWp] );

sub cmdWp {
	if (!$net || $net->getState() != Network::IN_GAME) {
		error TF("You must be logged in the game to use this command (%s)\n", shift);
		return;
	}
	my (undef, $args) = @_;
	my ($arg1, $arg2, $arg3) = $args =~ /^(.+?) (.+?)(?: (.*))?$/;

	my ($map, $x, $y);
	if ($arg1 eq "") {
		# map name or portal number
		$map = $args;
	} elsif ($arg3 eq "") {
		# coordinates
		$x = $arg1;
		$y = $arg2;
		$map = $field->baseName;
	} elsif ($arg1 =~ /^\d+$/) {
		# coordinates and map
		$x = $arg1;
		$y = $arg2;
		$map = $arg3;
	} else {
		# map and coordinates
		$x = $arg2;
		$y = $arg3;
		$map = $arg1;
	}
	
	if ((($x !~ /^\d+$/ || $y !~ /^\d+$/) && $arg1 ne "") || ($args eq "")) {
		error T("Syntax Error in function 'wp' (WayPoint)\n" .
			"Usage: wp <x> <y> [<map>]\n" .
			"       wp <map> [<x> <y>]\n" .
			"       wp <map>\n" .
			"       wp <portal#>\n");
	} else {
		AI::clear(qw/move route mapRoute/);
		if ($currentChatRoom ne "") {
			error T("Error in function 'wp' (WayPoint)\n" .
				"Unable to walk while inside a chat room!\n" .
				"Use the command: chat leave\n");
		} elsif ($shopstarted) {
			error T("Error in function 'wp' (WayPoint)\n" .
				"Unable to walk while the shop is open!\n" .
				"Use the command: closeshop\n");
		} else {
			if ($maps_lut{"${map}.rsw"}) {
				if ($x ne "") {
					message TF("Walking to waypoint: %s(%s): %s, %s\n", 
						$maps_lut{$map.'.rsw'}, $map, $x, $y), "route";
				} else {
					message TF("Walking to waypoint: %s(%s)\n", 
						$maps_lut{$map.'.rsw'}, $map), "route";
				}
			main::ai_route($map, $x, $y,
				attackOnRoute => 2,
				noSitAuto => 1,
				notifyUponArrival => 1);
			} elsif ($map =~ /^\d+$/) {
				if ($portalsID[$map]) {
					message TF("Walking into portal number %s (%s,%s)\n", 
						$map, $portals{$portalsID[$map]}{'pos'}{'x'}, $portals{$portalsID[$map]}{'pos'}{'y'});
					main::ai_route($field->baseName, $portals{$portalsID[$map]}{'pos'}{'x'}, $portals{$portalsID[$map]}{'pos'}{'y'}, attackOnRoute => 2, noSitAuto => 1);
				} else {
					error T("No portals exist.\n");
				}
			} else {
				error TF("Map %s does not exist\n", $map);
			}
		}
	}
}

sub Reload {
	Commands::unregister($cmdHook);
	message "WayPoint plugin reloading\n", 'success';
}
sub Unload {
	Commands::unregister($cmdHook);
	message " WayPoint plugin unloading, ", 'success';
}

1;