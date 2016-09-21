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
#
#  $Revision: 5555 $
#  $Id: ServerType8.pm 5555 2007-03-21 16:23:01Z vcl_kore $
#  Modified by skseo, Jan-24-2007, Fixed bugs.
########################################################################
# Korea (kRO), after February 2007
# Servertype overview: http://wiki.openkore.com/index.php/ServerType
package Network::Send::ServerType8_1;

use strict;
use Globals qw($accountID $sessionID $sessionID2 $accountSex $char $charID %config %guild @chars $masterServer $syncSync $net);
use Network::Send::ServerType8;
use base qw(Network::Send::ServerType8);
use Log qw(message warning error debug);
use I18N qw(stringToBytes);
use Utils qw(getTickCount getHex getCoordString);

sub new {
	my ($class) = @_;
	return $class->SUPER::new(@_);
}

sub sendAttack {
	my ($self, $monID, $flag) = @_;
	
	my %args;
	$args{monID} = $monID;
	$args{flag} = $flag;
	Plugins::callHook('packet_pre/sendAttack', \%args);
	if ($args{return}) {
		$self->sendToServer($args{msg});
		return;
	}

	my $msg = pack("C*", 0x90, 0x01) . pack("x7") . $monID . pack("x9 C1", $flag);
	$self->sendToServer($msg);
	debug "Sent attack: ".getHex($monID)."\n", "sendPacket", 2;
}

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
	
	my $msg = pack("C*", 0x16, 0x01) . pack("x4") .pack("v*", $index) . pack("x7") . pack("v*", $amount);
	$self->sendToServer($msg);
	debug "Sent drop: $index x $amount\n", "sendPacket", 2;
}

sub sendGetPlayerInfo {
	my ($self, $ID) = @_;
	
	my $msg = pack("C*", 0x8c, 0x00) . pack("x8") . $ID;
	
	$self->sendToServer($msg);
	debug "Sent get player info: ID - ".getHex($ID)."\n", "sendPacket", 2;
}

sub sendItemUse {
	my ($self, $ID, $targetID) = @_;
	
	my $msg = pack("C*", 0x9f, 0x00) . pack("x5") . pack("v*", $ID) . pack("x7") . $targetID;

	$self->sendToServer($msg);
	debug "Item Use: $ID\n", "sendPacket", 2;
}

sub sendLook {
	my ($self, $body, $head) = @_;
	
	my $msg = pack("C*", 0x85, 0x00) . pack("x2") . pack("C*", $head) . pack("x4") . pack("C*", $body);

	$self->sendToServer($msg);
	debug "Sent look: $body $head\n", "sendPacket", 2;
	$char->{look}{head} = $head;
	$char->{look}{body} = $body;
}

sub sendMapLogin {
	my ($self, $accountID, $charID, $sessionID, $sex) = @_;
	$sex = 0 if ($sex > 1 || $sex < 0); # Sex can only be 0 (female) or 1 (male)
	
	my $msg = pack("C*", 0x9b, 0) . pack("x5") .$accountID . pack("x4") . $charID . pack("x6") . $sessionID . pack("V", getTickCount()) . pack("C*", $sex);

	$self->sendToServer($msg);
}

sub sendMove {
	my $self = shift;
	my $x = int scalar shift;
	my $y = int scalar shift;
	
	my $msg = pack("C*", 0xA7, 0x00) . pack("x3") . getCoordString($x, $y);

	$self->sendToServer($msg);
	debug "Sent move to: $x, $y\n", "sendPacket", 2;
}


sub sendSit {
	my $self = shift;
	
	my %args;
	$args{flag} = 2;
	Plugins::callHook('packet_pre/sendSit', \%args);
	if ($args{return}) {
		$self->sendToServer($args{msg});
		return;
	}
	
	my $msg = pack("C2 x20 C1", 0x90, 0x01, 0x02);

	$self->sendToServer($msg);
	debug "Sitting\n", "sendPacket", 2;


}

sub sendStand {
	my $self = shift;

	my %args;
	$args{flag} = 3;
	Plugins::callHook('packet_pre/sendStand', \%args);
	if ($args{return}) {
		$self->sendToServer($args{msg});
		return;
	}	
	
	my $msg = pack("C2 x20 C1", 0x90, 0x01, 0x03);

	$self->sendToServer($msg);
	debug "Standing\n", "sendPacket", 2;
}

sub sendSkillUse {
	my $self = shift;
	my $ID = shift;
	my $lv = shift;
	my $targetID = shift;
	
	my %args;
	$args{ID} = $ID;
	$args{lv} = $lv;
	$args{targetID} = $targetID;
	Plugins::callHook('packet_pre/sendSkillUse', \%args);
	if ($args{return}) {
		$self->sendToServer($args{msg});
		return;
	}

	my $msg = pack("C*", 0x72, 0x00) . pack("x7") . pack("v*", $lv) . pack("x4") . pack("v*", $ID) . pack("x1") . $targetID;

	$self->sendToServer($msg);
	debug "Skill Use: $ID\n", "sendPacket", 2;
}

sub sendSkillUseLoc {
	my ($self, $ID, $lv, $x, $y) = @_;
	
	my $msg = pack("C*", 0x17, 0x01) . pack("v*", $ID) . pack("x4") . pack("v*", $lv) . pack("x12") . pack("v*", $x) . pack("C*", 0x19, 0xea, 0x4d, 0x09) . pack("v*", $y);

	$self->sendToServer($msg);
	debug "Skill Use on Location: $ID, ($x, $y)\n", "sendPacket", 2;
}

sub sendStorageAdd {
	my $self= shift;
	my $index = shift;
	my $amount = shift;
	
	my $msg = pack("C*", 0x94, 0x00) . pack("x1") . pack("v*", $index) . pack("x10") . pack("V*", $amount);
	
	$self->sendToServer($msg);
	debug "Sent Storage Add: $index x $amount\n", "sendPacket", 2;
}

sub sendStorageGet {
	my ($self, $index, $amount) = @_;

	my $msg = pack("C*", 0xf7, 0x00) . pack("x1") . pack("v*", $index) . pack("x8") . pack("V*", $amount);
	$self->sendToServer($msg);
	debug "Sent Storage Get: $index x $amount\n", "sendPacket", 2;
}

sub sendStorageClose {
	my ($self) = @_;
	my $msg = pack("C*", 0x93, 0x01);
	$self->sendToServer($msg);
	debug "Sent Storage Done\n", "sendPacket", 2;
}

sub sendSync {
	my ($self, $initialSync) = @_;
	my $msg;
	# XKore mode 1 lets the client take care of syncing.
	return if ($self->{net}->version == 1);

	$syncSync = pack("V", getTickCount());
	
	my $msg = pack("C2 x5", 0x89, 0x00) . $syncSync;
	$self->sendToServer($msg);
	debug "Sent Sync\n", "sendPacket", 2;
}

sub sendTake {
	my $self = shift;
	my $itemID = shift; # $itemID = long
	
	my $msg = pack("C*", 0xf5, 0x00) . pack("x5") . $itemID;
	$self->sendToServer($msg);
	debug "Sent take\n", "sendPacket", 2;
}

1;
