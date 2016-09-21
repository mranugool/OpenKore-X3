#########################################################################
#  OpenKore - Waiting task
#  Copyright (c) 2006 OpenKore Developers
#
#  This software is open source, licensed under the GNU General Public
#  License, version 2.
#  Basically, this means that you're allowed to modify and distribute
#  this software. However, if you distribute modified versions, you MUST
#  also distribute the source code.
#  See http://www.gnu.org/licenses/gpl.html for the full license.
#########################################################################
# This tasks does nothing but waiting a specified number of seconds.
# It can be used in combination with @MODULE(Task::Chained).
#
# If this task is interrupted, then the time spent on interruption will not be counted.
# The time this task spent while not being logged in the game, may or may not be counted,
# depending on a configuration option.
#
# Example usage:
# <pre class="example">
# my $waitTask = new Task::Wait(
#         seconds => 3,
#         inGame => 1);
# </pre>
package Task::Wait;

use strict;
use Time::HiRes qw(time);

use Modules 'register';
use Task;
use base qw(Task);
use Globals qw($net);
use Utils qw(timeOut);
use Network;

### CATEGORY: Constructor

##
# Task::Wait->new(options...)
#
# Create a new Task::Wait object. The following options are allowed:
# `l`
# - All options allowed for Task->new(), except 'mutexes'.
# - seconds - The number of seconds to wait before marking this task as done or running a subtask.
# - inGame - Whether this task should only do things when we're logged into the game.
#            If not specified, 0 is assumed.
#            If inGame is set to 1 and we're not logged in, then the time we spent while not
#            being logged in does not count as waiting time.
# `l`
sub new {
	my $class = shift;
	my %args = @_;
	my $self = $class->SUPER::new(@_);

	$self->{wait}{timeout} = $args{seconds};
	$self->{inGame} = defined($args{inGame}) ? $args{inGame} : 1;

	return $self;
}

sub interrupt {
	my ($self) = @_;
	$self->SUPER::interrupt();
	$self->{interruptionTime} = time;
}

sub resume {
	my ($self) = @_;
	$self->SUPER::resume();
	$self->{wait}{time} += time - $self->{interruptionTime};
}

sub iterate {
	my ($self) = @_;
	$self->SUPER::iterate();
	return unless (!$self->{inGame} || $net->getState() == Network::IN_GAME);

	$self->{wait}{time} = time if (!defined $self->{wait}{time});
	$self->setDone() if (timeOut(\%{$self->{wait}}));
}

1;