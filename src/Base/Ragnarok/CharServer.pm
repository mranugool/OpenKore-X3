package Base::Ragnarok::CharServer;

use strict;
use Time::HiRes qw(time);
use Socket qw(inet_aton);

use Modules 'register';
use Base::RagnarokServer;
use base qw(Base::RagnarokServer);
use Misc;
use I18N qw(stringToBytes);
use Globals qw(%config $accountID $field %charSvrSet $masterServer);

use constant SESSION_TIMEOUT => 120;
use constant DUMMY_CHARACTER => {
	charID => pack("V", 1234),
	lv_job => 50,
	hp => 1,
	hp_max => 1,
	sp => 1,
	sp_max => 1,
	walk_speed => 1,
	jobID => 8, # Priest
	hair_style => 2,
	lv => 1,
	hair_color => 5,
	clothes_color => 1,
	name => 'Character',
	str => 1,
	agi => 1,
	vit => 1,
	dex => 1,
	luk => 1,
	int => 1,
	look => {
		head => 3,
		body => 3
	}
};

our $nChar = 0;

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
	$self->{mapServer} = $options{mapServer};
	$self->{name} = $options{name} || 'Ragnarok Online';
	$self->{charBlockSize} = $options{charBlockSize} || 106;
	return $self;
}

sub getName {
	return $_[0]->{name};
}

sub getPlayersCount {
	return 0;
}

sub getCharacters {
	die "This is an abstract method and has not been implemented.";
}

sub charBlockSize {
	return $_[0]->{charBlockSize};
}

sub game_login {
	# Character server login.
	my ($self, $args, $client) = @_;
	# maybe sessionstore should store sessionID as bytes?
	my $session = $self->{sessionStore}->get(unpack('V', $args->{sessionID}));

	unless (
		$session && $session->{accountID} eq $args->{accountID}
		# maybe sessionstore should store sessionID as bytes?
		&& pack('V', $session->{sessionID}) eq $args->{sessionID}
		&& $session->{sex} == $args->{accountSex}
		&& $session->{state} eq 'About to select character'
	) {
		$client->close();

	} else {
		$self->{sessionStore}->mark($session);
		$client->{session} = $session;
		$session->{time} = time;
		$client->send($args->{accountID});

		my $output = '';
		if ($self->{recvPacketParser}{packet_lut}{received_characters} eq '099D') {
			$output = $self->{recvPacketParser}->reconstruct({
				switch => 'received_characters_info',
				normal_slot => $charSvrSet{normal_slot},
				premium_slot => $charSvrSet{premium_slot},
				billing_slot => $charSvrSet{billing_slot},
				producible_slot => $charSvrSet{producible_slot},
				valid_slot => $charSvrSet{valid_slot},
			});
			if ($charSvrSet{sync_Count} > 0) {
				$output .= $self->{recvPacketParser}->reconstruct({
					switch => 'sync_received_characters',
					sync_Count => $charSvrSet{sync_Count},
				});
			}
			$client->send($output);
			&sendCharInfo if ($charSvrSet{sync_Count} == 0);

		} else {
			no encoding 'utf8';
			use bytes;
	
			# Show list of characters.
			my $output = '';
			my $index = -1;
			foreach my $char ($self->getCharacters($session)) {
				$index++;
				next if (!$char);
	
				$output .= pack(
					$self->{recvPacketParser}->received_characters_unpackString,
					$char->{charID},	# character ID
					$char->{exp},		# base experience
					$char->{zeny},		# zeny
					$char->{exp_job},	# job experience
					$char->{lv_job},
					$char->{opt1},
					$char->{opt2},
					$char->{option},
					0,
					0,
					$char->{points_free},
					$char->{hp},
					$char->{hp_max},
					$char->{sp},
					$char->{sp_max},
					$char->{walk_speed} * 1000,
					$char->{jobID},
					$char->{hair_style},
					$char->{weapon}, # FIXME
					$char->{lv},
					$char->{points_skill},
					$char->{headgear}{low},
					$char->{shield}, # FIXME
					$char->{headgear}{top},
					$char->{headgear}{mid},
					$char->{hair_color},
					$char->{clothes_color},
					stringToBytes($char->{name}),
					$char->{str},
					$char->{agi},
					$char->{vit},
					$char->{int},
					$char->{dex},
					$char->{luk},
					0, 0, 1,
					$field?$field->baseName:'prontera',
					0,
				);
			}
			
			# FIXME
			if ($self->{serverType} == 8 || $self->{serverType} =~ /^kRO_/){
				$output = pack('C20') . $output;
			}
	
			# SECURITY NOTE: the session should be marked as belonging to this
			# character server only. Right now there is the possibility that
			# someone can login to another character server with a session
			# that was already handled by this one.
	
			$self->{sessionStore}->mark($session);
			$client->{session} = $session;
			$session->{time} = time;
			if ($config{XKore_altCharServer} == 1){
				$client->send(pack('C2 v', 0x72, 0x00, length($output) + 4) . $output);
			}else{
				# construct packet
				my $data;
				if ($masterServer->{serverType} eq 'bRO') {
					# 0x82D
					# len normal_slot premium_slot billing_slot producible_slot valid_slot charInfo
					#my $
					$data = pack('v2 C5 x20 a*', 0x82D, 29+length($output),
																			$charSvrSet{normal_slot} || 9,
																			$charSvrSet{premium_slot} || 0,
																			$charSvrSet{billing_slot} || 0,
																			$charSvrSet{producible_slot} || 0,
																			$charSvrSet{valid_slot} || 9,
																			$output);
				} else {
					$data = $self->{recvPacketParser}->reconstruct({ # will always reconstruct 006B
						switch => 'received_characters',
						charInfo => $output,
						
						# "if number of characters exceed 0 on selecting window, connection to game can't not be made" (sic)
						total_slot => $charSvrSet{normal_slot} || 9,
						
						# slots in premium range are displayed as "Not Available"
						premium_start_slot => $charSvrSet{normal_slot} || 9,
						premium_end_slot => $charSvrSet{normal_slot} || 9,

						normal_slot => $charSvrSet{normal_slot} || 9,
						premium_slot => $charSvrSet{premium_slot} || 9,
						billing_slot => $charSvrSet{billing_slot} || 9,
					});
				}
				$data .= pack('C2 x4 a4 v', 0xB9, 0x08, $args->{accountID}, 0); #add accountID
				$client->send($data);
			}
		}
	}
}

sub sendCharInfo {
	no encoding 'utf8';
	use bytes;
	my ($self, $args, $client) = @_;
	my $session = $client->{session};

	# Show list of characters.
	if ($session) {
		my $output = '';
		my $index = -1;
		foreach my $char ($self->getCharacters($session)) {
			$index++;
			next if (!$char);
	
			$output .= pack(
				$self->{recvPacketParser}->received_characters_unpackString,
				$char->{charID},	# character ID
				$char->{exp},		# base experience
				$char->{zeny},		# zeny
				$char->{exp_job},	# job experience
				$char->{lv_job},
				$char->{opt1},
				$char->{opt2},
				$char->{option},
				0,
				0,
				$char->{points_free},
				$char->{hp},
				$char->{hp_max},
				$char->{sp},
				$char->{sp_max},
				$char->{walk_speed} * 1000,
				$char->{jobID},
				$char->{hair_style},
				$char->{weapon}, # FIXME
				$char->{lv},
				$char->{points_skill},
				$char->{headgear}{low},
				$char->{shield}, # FIXME
				$char->{headgear}{top},
				$char->{headgear}{mid},
				$char->{hair_color},
				$char->{clothes_color},
				stringToBytes($char->{name}),
				$char->{str},
				$char->{agi},
				$char->{vit},
				$char->{int},
				$char->{dex},
				$char->{luk},
				0, 0, 0,
				$field->baseName,
				0,
			);
		}
		# FIXME
	    	if ($self->{serverType} == 8){
			$output = pack('C20') . $output;
		}
	
		# SECURITY NOTE: the session should be marked as belonging to this
		# character server only. Right now there is the possibility that
		# someone can login to another character server with a session
		# that was already handled by this one.
	
		if ($config{XKore_altCharServer} == 1){
			$client->send(pack('C2 v', 0x72, 0x00, length($output) + 4) . $output);
		}else{
			$client->send($self->{recvPacketParser}->reconstruct({
				switch => 'received_characters',
				charInfo => $output,
			}));
		}
	}
}

sub char_login {
	# Select character.
	my ($self, $args, $client) = @_;
	my $session = $client->{session};
	if ($session) {
		$self->{sessionStore}->mark($session);
		my @characters = $self->getCharacters();
		if (!$characters[$args->{slot}]) {
			# Invalid character selected.
			$client->send(pack('C*', 0x6C, 0x00, 0));
		} else {
			my $char = $characters[$args->{slot}];
			my $charInfo = $self->{mapServer}->getCharInfo($session);
			if (!$charInfo) {
				# We can't get the character information for some reason.
				$client->send(pack('C*', 0x6C, 0x00, 0));
			} else {
				my $host = inet_aton($self->{mapServer}->getHost);
				$host = inet_aton($client->{BSC_sock}->sockhost) if $host eq "\000\000\000\000";
				
				$session->{charID} = $char->{charID};
				$session->{state} = 'About to load map';
				$client->send($self->{recvPacketParser}->reconstruct({
					switch => 'received_character_ID_and_Map',
					charID => $char->{charID},
					mapName => $charInfo->{map},
					mapIP => $host,
					mapPort => $self->{mapServer}->getPort,
				}));
			}
		}
	}
	$client->close();
}

sub sync_received_characters {
	my ($self, $args, $client) = @_;
	if ($nChar == 0) {
		&sendCharInfo;
		$nChar = 1;
	} else {
		$client->send($self->{recvPacketParser}->reconstruct({
			switch => 'login_pin_code_request',
			seed => 0,
			accountID => $accountID,
			flag => 7,
		}));
		$nChar = 0;
	}
}

sub ban_check {
	# Ban check.
	# Doing nothing seems to work.
	my ($self, $ID, $client) = @_;
	$client->send($self->{recvPacketParser}->reconstruct({
		switch => 'sync_request',
		accountID => $ID,
	}));
}

sub char_create {
	# Character creation.
	my ($self, $args, $client) = @_;
	# Deny it.
	$client->send(pack('C*', 0x6E, 0x00, 2));
}

sub char_delete {
	# Character deletion.
	my ($self, $args, $client) = @_;
	# Deny it.
	$client->send(pack('C*', 0x70, 0x00, 1));
}

sub unhandledMessage {
	my ($self, $args, $client) = @_;
	$client->close();
}

1;
