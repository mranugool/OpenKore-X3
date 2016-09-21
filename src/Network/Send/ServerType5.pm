#########################################################################
#  OpenKore - Packet sending
#  This module contains functions for sending packets to the server.
#
#  This software is open source, licensed under the GNU General Public
#  License, version 2.
#  Basically, this means that you're allowed to modify and distribute
#  this software. However, if you distribute modified versions, you MUST
#  also distribute the source code.
#  See http://www.gnu.org/licenses/gpl.html for the full license.
#########################################################################
# Servertype overview: http://wiki.openkore.com/index.php/ServerType
package Network::Send::ServerType5;

use strict;
use Globals qw($accountID $sessionID $sessionID2 $accountSex $char $charID %config %guild @chars $masterServer $syncSync $net);
use Network::Send::ServerType0;
use base qw(Network::Send::ServerType0);
use Log qw(message warning error debug);
use I18N qw(stringToBytes);
use Utils qw(getTickCount getHex getCoordString);

sub new {
	my ($class) = @_;
	return $class->SUPER::new(@_);
}

sub sendGetCharacterName {
	my ($self, $ID) = @_;
	my $msg = pack("C*", 0xa2, 0x00, 0x00, 0x00, 0x00) . $ID;
	$self->sendToServer($msg);
	debug "Sent get character name: ID - ".getHex($ID)."\n", "sendPacket", 2;
}

# 0x0190,24,actionrequest,11:23
sub sendAction { # flag: 0 attack (once), 7 attack (continuous), 2 sit, 3 stand
	my ($self, $monID, $flag) = @_;

	my %args;
	$args{monID} = $monID;
	$args{flag} = $flag;
	# eventually we'll trow this hooking out so...
	Plugins::callHook('packet_pre/sendAttack', \%args) if ($flag == 0 || $flag == 7);
	Plugins::callHook('packet_pre/sendSit', \%args) if ($flag == 2 || $flag == 3);
	if ($args{return}) {
		$self->sendToServer($args{msg});
		return;
	}

	my $msg = pack('v x9 a4 x8 C', 0x0190, $monID, $flag);
	$self->sendToServer($msg);
	debug "Sent Action: " .$flag. " on: " .getHex($monID)."\n", "sendPacket", 2;
}

=pod
sub sendAttack {
	my ($self, $monID, $flag) = @_;
	my $msg;
	
	$msg = pack("C*", 0x90, 0x01, 0x00, 0x40, 0x00, 0x00, 0x00, 0x00, 0x08, 0xb0, 0x58) .
		$monID .
		pack("C*", 0x3f, 0x74, 0xfb, 0x12, 0x00, 0xd0, 0xda, 0x63, $flag);
		
 	$self->sendToServer($msg);
	debug "Sent attack: ".getHex($monID)."\n", "sendPacket", 2;
}
sub sendSit {
	my $self = shift;
	my $msg;

	$msg = pack("C*", 0x90, 0x01, 0x00, 0x40, 0x00, 0x00, 0x00, 0x00, 0x08, 0xb0, 0x58,
		0x00, 0x00, 0x00, 0x00, 0x3f, 0x74, 0xfb, 0x12, 0x00, 0xd0, 0xda, 0x63, 0x02);

	$self->sendToServer($msg);
	debug "Sitting\n", "sendPacket", 2;
}

sub sendStand {
	my $self = shift;
	my $msg;
	
	$msg = pack("C*", 0x90, 0x01, 0x00, 0x40, 0x00, 0x00, 0x00, 0x00, 0x08, 0xb0, 0x58,
		0x00, 0x00, 0x00, 0x00, 0x3f, 0x74, 0xfb, 0x12, 0x00, 0xd0, 0xda, 0x63, 0x03);
	
	$self->sendToServer($msg);
	debug "Standing\n", "sendPacket", 2;
}
=cut

sub sendChat {
	my ($self, $message) = @_;
	$message = "|00$message" if $masterServer->{chatLangCode};

	my ($data, $charName); # Type: Bytes
	$message = stringToBytes($message); # Type: Bytes
	$charName = stringToBytes($char->{name});
	
	$data = pack("C*", 0xf3, 0x00) .
		pack("v*", length($charName) + length($message) + 8) .
		$charName . " : " . $message . chr(0);
	
	$self->sendToServer($data);
}

sub sendDrop {
	my ($self, $index, $amount) = @_;
	my $msg;

	$msg = pack("C*", 0x16, 0x01, 0x4b) .
		pack("v*", $index) .
		pack("C*", 0x60, 0x13, 0x14, 0x82, 0x21) .
		pack("v*", $amount);

	$self->sendToServer($msg);
	debug "Sent drop: $index x $amount\n", "sendPacket", 2;
}

sub sendGetPlayerInfo {
	my ($self, $ID) = @_;
	my $msg;
	$msg = pack("C*", 0x8c, 0x00, 0x12, 0x00) . $ID;
	$self->sendToServer($msg);
	debug "Sent get player info: ID - ".getHex($ID)."\n", "sendPacket", 2;
}

sub sendItemUse {
	my ($self, $ID, $targetID) = @_;
	my $msg;
	
	$msg = pack("C*", 0x9f, 0x00, 0x12, 0x00, 0x00, 0xab ,0xca ,0x11 ,0x5c) .
		pack("v*", $ID) .
		pack("C*", 0x00, 0x18, 0xfb, 0x12) .
		$targetID;
			
	$self->sendToServer($msg);
	debug "Item Use: $ID\n", "sendPacket", 2;
}

sub sendLook {
	my ($self, $body, $head) = @_;
	my $msg;
	
	$msg = pack("C*", 0x85, 0x00, 0x54, 0x00, 0xD8, 0x5D, 0x2E, 0x14) .
		pack("C*", $head, 0x00, 0x00, 0x00, 0x08, 0x60, 0x13, 0x14) .
		pack("C*", $body);
	
	$self->sendToServer($msg);
	debug "Sent look: $body $head\n", "sendPacket", 2;
	$char->{look}{head} = $head;
	$char->{look}{body} = $body;
}

sub sendMapLogin {
	my ($self, $accountID, $charID, $sessionID, $sex) = @_;
	my $msg;
	$sex = 0 if ($sex > 1 || $sex < 0); # Sex can only be 0 (female) or 1 (male)
	
	$msg = pack("C*", 0x9b, 0, 0, 0x10) .
		pack("C*", 0, 0, 0, 0, 0) .
		$accountID .
		pack("C*", 0xfc, 0x12) .
		$charID .
		pack("C*", 0x00, 0xff, 0xff, 0xff) .
		$sessionID .
		pack("V", getTickCount()) .
		pack("C*", $sex);
		
	$self->sendToServer($msg);
}

sub sendMove {
	my $self = shift;
	my $x = int scalar shift;
	my $y = int scalar shift;
	my $msg;
	
	$msg = pack("C*", 0xa7, 0x00, 0x62, 0x13, 0x18, 0x13, 0x97, 0x11) .
		getCoordString($x, $y, 1);
	
	$self->sendToServer($msg);
	debug "Sent move to: $x, $y\n", "sendPacket", 2;
}

sub sendSkillUse {
	my ($self, $ID, $lv, $targetID) = @_;
	my $msg;
	
	$msg = pack("C*", 0x72, 0x00, 0x0d, 0x01, 0x32, 0x07) .
		pack("v*", $lv) .
		pack("C*", 0x07, 0x00, 0x00, 0x00, 0xd8, 0x07, 0x0d, 0x01, 0x00) .
		pack("v*", $ID) .
		pack("C*", 0x8e, 0x00, 0x01, 0xa8, 0x9a, 0x2b, 0x16, 0x12, 0x00, 0x00, 0x00) .
		$targetID;
	
	$self->sendToServer($msg);
	debug "Skill Use: $ID\n", "sendPacket", 2;
}

sub sendSkillUseLoc {
	my ($self, $ID, $lv, $x, $y) = @_;
	my $msg;
	
	$msg = pack("C*", 0x13, 0x01, 0x37, 0x65, 0x66, 0x60, 0x1C, 0xa0, 0xc0, 0x32, 0xBF, 0x00) .
		pack("v*", $lv) .
		pack("C*", 0x32) .
		pack("v*", $ID) .
		pack("C*", 0x3F) .
		pack("v*", $x) .
		pack("C*", 0x6D, 0x6E, 0x68, 0x3D, 0x68, 0x6F, 0x0C, 0x0C, 0x93, 0xE5, 0x5C) .
		pack("v*", $y);
	
	$self->sendToServer($msg);
	debug "Skill Use on Location: $ID, ($x, $y)\n", "sendPacket", 2;
}

sub sendStorageAdd {
	my ($self, $index, $amount) = @_;
	my $msg;
	
	$msg = pack("C*", 0x94, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00) .
		pack("C*", 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00) .
		pack("v*", $index) .
		pack("C*", 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x7b, 0x01, 0x00) .
		pack("V*", $amount);
	
	$self->sendToServer($msg);
	debug "Sent Storage Add: $index x $amount\n", "sendPacket", 2;
}

sub sendStorageGet {
	my ($self, $index, $amount) = @_;
	my $msg;

	$msg = pack("C*", 0xf7, 0x00, 0x00, 0x00) .
		pack("C*", 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00) .
		pack("v*", $index) .
		pack("C*", 0x00) .
		pack("V*", $amount);
	
	$self->sendToServer($msg);
	debug "Sent Storage Get: $index x $amount\n", "sendPacket", 2;
}

sub sendSync {
	my ($self, $initialSync) = @_;
	my $msg;
	# XKore mode 1 lets the client take care of syncing.
	return if ($self->{net}->version == 1);

	$syncSync = pack("V", getTickCount());
	
	$msg = pack("C*", 0x89, 0x00);
	$msg .= pack("C*", 0x00, 0x00, 0x40) if ($initialSync);
	$msg .= pack("C*", 0x00, 0x00, 0x1F) if (!$initialSync);
	$msg .= pack("C*", 0x00, 0x00, 0x00, 0x90);
	$msg .= $syncSync;
	
	$self->sendToServer($msg);
	debug "Sent Sync\n", "sendPacket", 2;
}

sub sendTake {
	my ($self, $itemID) = @_;
	my $msg;
	$msg = pack("C*", 0xf5, 0x00, 0x66, 0x00, 0xff, 0xff, 0xff, 0xff, 0x5c) . $itemID;
	$self->sendToServer($msg);
	debug "Sent take\n", "sendPacket", 2;
}

1;