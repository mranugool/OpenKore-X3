# A basic implementation of an RO account server.
# One should implement the abstract methods to implement a fully functional RO account server.
package Base::Ragnarok::AccountServer;

use strict;
use Digest::MD5;
use Exception::Class qw(
	Base::Ragnarok::AccountServer::AccountNotFound
	Base::Ragnarok::AccountServer::PasswordIncorrect
	Base::Ragnarok::AccountServer::AccountBanned
);

use Modules 'register';
use Base::RagnarokServer;
use base qw(Base::RagnarokServer);
use Globals qw($masterServer);
use Log qw(debug);
use Utils qw(getHex);
use Utils::Exceptions;
use Network::Receive::ServerType0; # constants only

use enum qw(LOGIN_SUCCESS ACCOUNT_NOT_FOUND PASSWORD_INCORRECT ACCOUNT_BANNED SERVER_REFUSED);


sub new {
	my $class = shift;
	my %options = @_;
	my $self = $class->SUPER::new(
		$options{host},
		$options{port},
		$options{serverType},
		$options{rpackets}
	);
	$self->{sessionStore} = $options{sessionStore};
	$self->{charServers} = [$options{charServer}];
	return $self;
}

##
# abstract int $Base_Ragnarok_AccountServer->login(Hash* session, String username, String password)
#
# This method is called whenever an RO client tries to login. It authenticates the
# specified user with the specified password, and fills the session hash with necessary
# session information upon success.
#
# Upon calling this method, the session hash already contains two members:
# `l
# - sessionID - A unique 32-bit integer for this login session.
# - sessionID2 - Another unique 32-bit integer for this login session.
# `l`
#
# If the username is incorrect, then ACCOUNT_NOT_FOUND is returned.
# If the password is incorrect, then PASSWORD_INCORRECT is returned.
# If the account is banned, then ACCOUNT_BANNED is returned.
#
# Otherwise (that is, login is successful) LOGIN_SUCCESS is returned. The session
# information hash must be filled with at least the following members:
# `l
# - accountID - The account's ID, as a raw byte string.
# - sex - Specifies the gender of this account. 0 means female, 1 means male.
# `l`
sub login {
	die "This is an abstract method and has not been implemented.";
}

sub secureKey {
	my ($self, $client) = @_;
	
	# FIXME: randomize for every client? Mimic the original server?
	'key'
}

sub master_login {
	my ($self, $args, $client) = @_;

	my $sessionID = $self->{sessionStore}->generateSessionID();
	my %session = (
		sessionID => $sessionID,
		sessionID2 => $sessionID
	);

	my $password_check = do {
		if (defined $args->{password_salted_md5}) {
			sub { $args->{password_salted_md5} eq $self->{sendPacketParser}->secureLoginHash($_[0], $self->secureKey($client), $masterServer->{secureLogin}) }
		} elsif (defined $args->{password_md5}) {
			sub { $args->{password_md5} eq Digest::MD5->new->add($_[0])->digest }
		} else {
			sub { $args->{password} eq $_[0] }
		}
	};

	my $result = $self->login(\%session, $args->{username}, $password_check);
	if ($result == LOGIN_SUCCESS) {
		$self->{sessionStore}->add(\%session);
		$session{state} = 'About to select character';

		# Show list of character servers.
		my @servers;
		foreach my $charServer (@{$self->{charServers}}) {
			my $ip = $charServer->getHost;
			$ip = $client->{BSC_sock}->sockhost if $ip =~ /^0\./;

			push @servers, {
				ip => $ip,
				port => $charServer->getPort,
				name => $charServer->getName,
				users => $charServer->getPlayersCount,
				display => 5, # don't show number of players
			};
		}
		
		$client->send($self->{recvPacketParser}->reconstruct({
			switch => 'account_server_info',
			# maybe sessionstore should store sessionID as bytes?
			sessionID => pack('V', $session{sessionID}),
			accountID => $session{accountID},
			sessionID2 => pack('V', $session{sessionID2}),
			accountSex => $session{sex},
			servers => \@servers,
		}));
		$client->close();

	} elsif ($result == ACCOUNT_NOT_FOUND) {
		$client->send($self->{recvPacketParser}->reconstruct({
			switch => 'login_error',
			type => Network::Receive::ServerType0::REFUSE_INVALID_ID,
		}));
		$client->close();
	} elsif ($result == PASSWORD_INCORRECT) {
		$client->send($self->{recvPacketParser}->reconstruct({
			switch => 'login_error',
			type => Network::Receive::ServerType0::REFUSE_INVALID_PASSWD,
		}));
		$client->close();
	} elsif ($result == ACCOUNT_BANNED) {
		$client->send($self->{recvPacketParser}->reconstruct({
			switch => 'login_error',
			type => Network::Receive::ServerType0::REFUSE_NOT_CONFIRMED,
		}));
		$client->close();
	} elsif ($result == SERVER_REFUSED) {
		$client->send($self->{recvPacketParser}->reconstruct({
			switch => 'login_error',
			type => Network::Receive::ServerType0::ACCEPT_ID_PASSWD,
		}));
		$client->close();
	} else {
		die "Unexpected result $result.";
	}
}

sub client_hash {
	my ($self, $args, $client) = @_;
	
	debug sprintf("Client hash: %s\n", getHex($args->{hash})), 'connection';
}

sub secure_login_key_request {
	my ($self, $args, $client) = @_;
	
	my $key = $self->secureKey($client);
	
	$client->send($self->{recvPacketParser}->reconstruct({
		switch => 'secure_login_key',
		secure_key => $key,
	}));
	
	debug sprintf("Client requests secure login. Secure login key: %s\n", getHex($key)), 'connection';
}

sub unhandledMessage {
	my ($self, $args, $client) = @_;
	$client->close();
}

1;
