#########################################################################
#  OpenKore - Error reporting task
#  Copyright (c) 2007 OpenKore Team
#
#  This software is open source, licensed under the GNU General Public
#  License, version 2.
#  Basically, this means that you're allowed to modify and distribute
#  this software. However, if you distribute modified versions, you MUST
#  also distribute the source code.
#  See http://www.gnu.org/licenses/gpl.html for the full license.
#########################################################################
##
# MODULE DESCRIPTION: Error reporting task.
#
# By default, tasks fail silently. That is, they don't print any error
# messages when they fail. You can wrap any task inside a Task::ErrorReport
# task to enable error reporting to the user. This avoids the need of
# writing error reporting code in every task.
#
# If the wrapped class finishes with an error, then the error message (as
# passed to $Task->setError()) will be printed on screen.
#
# Task::ErrorReport will mimic the wrappee's name, priority and mutexes.
#
# <h3>Example</h3>
# <pre class="example">
# my $originalTask = new Task::SitStand(mode => 'sit');
# my $task = new Task::ErrorReport(task => $originalTask);
# $taskManager->add($task);
# </pre>
package Task::ErrorReport;

use strict;
use Modules 'register';
use Task::WithSubtask;
use base qw(Task::WithSubtask);
use Log qw(error);

##
# Task::ErrorReport->new(options...)
#
# Create a new Task::ErrorReport object.
#
# The following options are allowed:
# `l
# - All options allowed by Task->new(), except 'mutexes'.
# - task (required) - The Task object to wrap.
# `l`
sub new {
	my $class = shift;
	my %args = @_;

	if (!$args{task}) {
		ArgumentException->throw("No task argument given.");
	}

	my $self = $class->SUPER::new(@_,
		autofail => 1,
		autostop => 1,
		manageMutexes => 1,
		priority => $args{task}->getPriority(),
		name => $args{task}->getName());
	$self->setSubtask($args{task});
	return $self;
}

sub subtaskDone {
	my ($self, $task) = @_;
	if ($task->getError()) {
		my $error = $task->getError();
		error "$error->{message}\n";
	} else {
		$self->setDone();
	}
}

1;
