#########################################################################
#  OpenKore - Sit/stand task
#  Copyright (c) 2004-2006 OpenKore Developers
#
#  This software is open source, licensed under the GNU General Public
#  License, version 2.
#  Basically, this means that you're allowed to modify and distribute
#  this software. However, if you distribute modified versions, you MUST
#  also distribute the source code.
#  See http://www.gnu.org/licenses/gpl.html for the full license.
#########################################################################
##
# MODULE DESCRIPTION: Sit/stand task.
#
# A task for sitting or standing. This task will keep sending sit or
# stand messages to the server until the character is actually sitting
# or standing.
package Task::SitStand;

use strict;
use Time::HiRes qw(time);

use Modules 'register';
use Task;
use base qw(Task);
use Globals qw(%timeout $net);
use Network;
use Skill;
use Translation qw(T);
use Utils qw(timeOut);
use Utils::Exceptions;

# Mutexes used by this task.
use constant MUTEXES => ['movement'];

# Error codes
use enum qw(NO_SIT_STAND_SKILL);

##
# Task::SitStand->new(options...)
#
# Create a new Task::SitStand object.
#
# The following options are allowed:
# `l
# - All options allowed for Task->new(), except 'mutexes'.
# - <tt>mode</tt> (required) - Either 'sit' or 'stand'. An ArgumentException will be thrown if you specify something else.
# - <tt>wait</tt> - Wait the specified number of seconds before actually trying to sit or stand. The default is 0.
# `l`
sub new {
	my $class = shift;
	my %args = @_;
	my $self = $class->SUPER::new(@_, mutexes => MUTEXES);

	unless ($args{actor}->isa('Actor') and $args{mode} eq 'sit' || $args{mode} eq 'stand') {
		ArgumentException->throw("Invalid arguments.");
	}

	$self->{$_} = $args{$_} for qw(actor mode);
	$self->{wait}{timeout} = $args{wait};
	$self->{retry}{timeout} = $timeout{ai_stand_wait}{timeout} || 1;
	# $self->{sitSkill} = new Skill(handle => 'NV_BASIC');

	return $self;
}

# Overrided method.
sub activate {
	my ($self) = @_;
	$self->SUPER::activate();
	$self->{wait}{time} = time;
}

# Overrided method.
sub interrupt {
	my ($self) = @_;
	$self->SUPER::interrupt();
	$self->{interruptionTime} = time;
}

# Overrided method.
sub resume {
	my ($self) = @_;
	$self->SUPER::resume();
	$self->{wait}{time} += time - $self->{interruptionTime};
	$self->{retry}{time} += time - $self->{interruptionTime};
}

# Overrided method.
sub iterate {
	my ($self) = @_;
	$self->SUPER::iterate();
	return unless ($net->getState() == Network::IN_GAME);

	unless ($self->{mode} eq 'sit' xor $self->{actor}{sitting}) {
		$self->setDone();
		$timeout{ai_sit}{time} = $timeout{ai_sit_wait}{time} = 0;

	} elsif ($self->{actor}->getSkillLevel(new Skill(handle => 'NV_BASIC')) < 3 && ($self->{actor}{jobID} == 0 || $self->{actor}{jobID} == 161)) {  # Check NV_BASIC skill only for Novice and High Novice
		$self->setError(NO_SIT_STAND_SKILL, T("Basic Skill level 3 is required in order to sit or stand."));

	} elsif (timeOut($self->{wait}) && timeOut($self->{retry})) {
		if ($self->{mode} eq 'stand') {
			$self->{actor}->sendStand;
		} else {
			$self->{actor}->sendSit;
		}
		$self->{retry}{time} = time;
	}
}

1;
