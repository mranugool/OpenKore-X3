#########################################################################
#  OpenKore - Socket interface
#
#  Copyright (c) 2007 OpenKore development team
#
#  This program is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 2 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#########################################################################
##
# MODULE DESCRIPTION: Socket interface.
#
# An interface which runs on a Unix socket. Any number of clients can
# connect to the socket to view OpenKore messages and to enter user input.
# This allows one to run OpenKore in the background without the use of tools
# like GNU screen.
#
# <h2>Protocol</h2>
#
# <h3>Passive vs active modes</h3>
# Clients can be in two modes:
# `l
# - Passive. In this state, no data is sent to the client unless the
#   client queries the server for certain information.
# - Active. In this state, the server will actively send the latest events
#   (new log messages, title changes, etc.) to the client.
# `l`
# Upon connecting to the server, a client is set to passive mode by default.
#
# The client can switch to passive or active modes with the messages
# "set passive" and "set active".
#
# <h3>Interface event messages</h3>
#
# <h4>output (server to client)</h4>
# This message is sent when a message is to be displayed on screen. It has the following
# parameters: "type", "message", "domain".
#
# <h4>title changed (server to client)</h4>
# This message is sent whenever the title of the interface is changed. It has one parameter, "title".
#
# <h4>input (client to server)</h4>
# Tell the server that the user has entered some text as input. It has one parameter, "data".
package Interface::Socket;

use strict;
use Time::HiRes qw(sleep);
use IO::Socket;
use Interface;
use Translation;
use base qw(Interface);
use Utils qw(timeOut);
use Interface::Console::Simple;

use constant MAX_LOG_ENTRIES => 5000;


sub new {
	my ($class) = @_;
	my (%self, $f);

	$self{server} = new Interface::Socket::Server();
	$self{console} = new Interface::Console::Simple();
	open($f, ">:utf8", "$Settings::logs_folder/console.log");
	$self{consoleLogFile} = $f;
	$self{logEntryCount} = 0;
	return bless \%self, $class;
}

sub iterate {
	my ($self) = @_;
	$self->{server}->iterate();
}

sub getInput {
	my ($self, $timeout) = @_;
	my $line;

	if ($timeout < 0) {
		$self->{server}->setWaitingForInput(1);
		while (!defined($line)) {
			if (my $input = $self->{console}->getInput(0)) {
				$self->{server}->addInput($input);
			}
			if ($self->{server}->hasInput()) {
				$line = $self->{server}->getInput();
			} else {
				$self->{server}->iterate();
				sleep 0.01;
			}
		}
		$self->{server}->setWaitingForInput(0);

	} elsif ($timeout == 0) {
		if ($self->{server}->hasInput()) {
			$line = $self->{server}->getInput();
		}

	} else {
		my %time = (time => time, timeout => $timeout);
		$self->{server}->setWaitingForInput(1);
		while (!defined($line) && !timeOut(\%time)) {
			if (my $input = $self->{console}->getInput(0)) {
				$self->{server}->addInput($input);
			}
			if ($self->{server}->hasInput()) {
				$line = $self->{server}->getInput();
			} else {
				$self->{server}->iterate();
				sleep 0.01;
			}
		}
		$self->{server}->setWaitingForInput(0);
	}

	return $line;
}

sub writeOutput {
	my $self = shift;
	$self->{server}->addMessage(@_);
	$self->{console}->writeOutput(@_);
	if ($self->{consoleLogFile}) {
		$self->{logEntryCount}++;
		if ($self->{logEntryCount} < MAX_LOG_ENTRIES) {
			$self->{consoleLogFile}->print($_[1]);
		} else {
			truncate $self->{consoleLogFile}, 0;
			$self->{consoleLogFile}->print($self->{server}->getScrollbackBuffer());
		}
		$self->{consoleLogFile}->flush();
	}
}

sub title {
	my ($self, $title) = @_;
	if ($title) {
		if (!defined($self->{title}) || $self->{title} ne $title) {
			$self->{title} = $title;
			$self->{server}->setTitle($title);
			$self->{console}->title($title);
		}
	} else {
		return $self->{title};
	}
}

sub errorDialog {
	my ($self, $message, $fatal) = @_;
	$fatal = 1 unless defined $fatal;

	$self->writeOutput("error", "$message\n", "error");
	if ($fatal) {
		$self->writeOutput("message", Translation::T("Enter 'e' or 'q' to exit this program.\n"), "console")
	} else {
		$self->writeOutput("message", Translation::T("Enter 'c' to continue...\n"), "console")
	}
	$self->getInput(-1);
}


package Interface::Socket::Server;

use strict;
use IO::Socket::UNIX;
use Base::Server;
use base qw(Base::Server);
use Settings;
use Bus::Messages qw(serialize);
use Bus::MessageParser;

use constant MAX_MESSAGE_SCROLLBACK => 20;

# Client modes.
use enum qw(PASSIVE ACTIVE);

sub new {
	my ($class) = @_;
	my $socket_file = "$Settings::logs_folder/console.socket";
	my $pid_file = "$Settings::logs_folder/openkore.pid";
	my $socket = new IO::Socket::UNIX(
		Local => $socket_file,
		Type => SOCK_STREAM,
		Listen => 5
	);
	if (!$socket && $! == 98) {
		$socket = new IO::Socket::UNIX(
			Peer => $socket_file,
			Type => SOCK_STREAM
		);
		if (!$socket) {
			unlink($socket_file);
			$socket = new IO::Socket::UNIX(
				Local => $socket_file,
				Type => SOCK_STREAM,
				Listen => 5
			);
		} else {
			print STDERR "There is already an OpenKore instance listening at '$socket_file'.\n";
			exit 1;
		}
	}
	if (!$socket) {
		print STDERR "Cannot listen at '$socket_file': $!\n";
		exit 1;
	}

	my $f;
	if (open($f, ">", $pid_file)) {
		print $f $$;
		close($f);
	} else {
		unlink $socket_file;
		print STDERR "Cannot write to PID file '$pid_file'.\n";
		exit 1;
	}

	my $self = $class->SUPER::createFromSocket($socket);
	$self->{parser} = new Bus::MessageParser();
	# A message log, used to sent the last MAX_MESSAGE_SCROLLBACK messages to
	# the client when that client switches to active mode.
	$self->{messages} = [];
	$self->{inputs} = [];
	$self->{socket_file} = $socket_file;
	$self->{pid_file} = $pid_file;
	$self->{waitingForInput} = 0;

	$SIG{INT} = $SIG{TERM} = $SIG{QUIT} = sub {
		unlink $socket_file;
		unlink $pid_file;
		exit 2;
	};

	return $self;
}

sub DESTROY {
	my ($self) = @_;
	unlink $self->{socket_file};
	unlink $self->{pid_file};
	$self->SUPER::DESTROY();
}

#### Public methods ####

sub addMessage {
	my ($self, $type, $message, $domain) = @_;
	$self->broadcast("output", {
		type    => $type,
		message => $message,
		domain  => $domain
	});
	# Add to message log.
	push @{$self->{messages}}, [$type, $message, $domain];
	if (@{$self->{messages}} > MAX_MESSAGE_SCROLLBACK) {
		shift @{$self->{messages}};
	}
}

# Broadcast a message to all clients.
sub broadcast {
	my $self = shift;
	my $clients = $self->clients();
	if (@{$clients} > 0) {
		my $messageID = shift;
		my $message = serialize($messageID, @_);
		foreach my $client (@{$clients}) {
			if ($client->{mode} == ACTIVE) {
				$client->send($message);
			}
		}
	}
}

# Check there is anything in the input queue.
sub hasInput {
	my ($self) = @_;
	return @{$self->{inputs}} > 0;
}

# Get the first input from the input queue.
sub getInput {
	my ($self) = @_;
	return shift @{$self->{inputs}};
}

# Put something in the input queue.
sub addInput {
	my ($self, $input, $client) = @_;
	push @{$self->{inputs}}, $input;
	
	# Tell all clients, except the one that generated this input,
	# that new input is received.
	my $clients = $self->clients();
	my $message = serialize('inputted', { data => $input });
	foreach my $client (@{$clients}) {
		if ($client->{mode} == ACTIVE) {
			$client->send($message);
		}
	}
}

sub setTitle {
	my ($self, $title) = @_;
	$self->{title} = $title;
	$self->broadcast("title changed", { title => $title });
}

sub setWaitingForInput {
	my ($self, $waitingForInput) = @_;
	$self->{waitingForInput} = $waitingForInput;
}

sub getScrollbackBuffer {
	my ($self) = @_;
	my $text = '';
	foreach my $message (@{$self->{messages}}) {
		$text .= $message->[1];
	}
	return $text;
}


#### Protected overrided methods ####

sub onClientNew {
	my ($self, $client) = @_;
	$client->{mode} = PASSIVE;
}

sub onClientData {
	my ($self, $client, $data) = @_;
	$self->{parser}->add($data);

	my $ID;
	while (my $args = $self->{parser}->readNext(\$ID)) {
		if ($ID eq "input") {
			$self->addInput($args->{data}, $client);

		} elsif ($ID eq "set active") {
			$client->{mode} = ACTIVE;
			# Send the last few messages and the current title.
			foreach my $entry (@{$self->{messages}}) {
				my $message = serialize("output", {
					type    => $entry->[0],
					message => $entry->[1],
					domain  => $entry->[2]
				});
				$client->send($message);
			}
			$client->send(serialize("title changed", { title => $self->{title} })) if ($self->{title});

		} elsif ($ID eq "set passive") {
			$client->{mode} = PASSIVE;
		}
	}
}

1;