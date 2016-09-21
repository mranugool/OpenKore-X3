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
#  $Revision: 6687 $
#  $Id: kRO.pm 6687 2009-04-19 19:04:25Z technologyguild $
########################################################################
# Korea (kRO)
# The majority of private servers use eAthena, this is a clone of kRO

package Network::Send::kRO::Sakexe_2005_07_18a;

use strict;
use base qw(Network::Send::kRO::Sakexe_2005_06_28a);

use Log qw(debug);
use I18N qw(stringToBytes);

sub version {
	return 18;
}

sub new {
	my ($class) = @_;
	my $self = $class->SUPER::new(@_);
	
	my %packets = (
		'0072' => ['skill_use', 'x3 V x2 v x2 a4', [qw(lv skillID targetID)]],#19
		'0085' => ['actor_look_at', 'x4 C x3 C', [qw(head body)]],
		'0089' => ['sync', 'x V', [qw(time)]],
		'008C' => ['actor_info_request', 'x5 a4', [qw(ID)]],
		'0094' => ['storage_item_add', 'x10 v x3 V', [qw(index amount)]],
		'009B' => ['map_login', 'x a4 x6 a4 x5 a4 V C', [qw(accountID charID sessionID tick sex)]],
		'009F' => ['item_use', 'x v x3 a4', [qw(index targetID)]],#12
		'00A2' => ['actor_name_request', 'x12 a4', [qw(ID)]],
		'00A7' => ['character_move', 'x10 a3', [qw(coords)]],
		'00F5' => ['item_take', 'x a4', [qw(ID)]],
		'00F7' => ['storage_item_remove', 'x3 v x2 V', [qw(index amount)]],
		'0113' => ['skill_use_location', 'x7 v x4 v x6 v x3 v', [qw(lv skillID x y)]],
		'0116' => ['item_drop', 'x4 v x2 v', [qw(index amount)]],
		'0190' => ['actor_action', 'x3 a4 x11 C', [qw(targetID type)]],
	);
	$self->{packet_list}{$_} = $packets{$_} for keys %packets;
	
	$self;
}

sub sendSkillUseLocInfo {
	my ($self, $ID, $lv, $x, $y, $moreinfo) = @_;
	my $msg = pack('v x7 v x4 v x6 v x3 v Z80', 0x007E, $lv, $ID, $x, $y, $moreinfo);
	$self->sendToServer($msg);
	debug "Skill Use on Location: $ID, ($x, $y)\n", "sendPacket", 2;
}

sub sendMailboxOpen {
	$_[0]->sendToServer(pack('v', 0x023F));
	debug "Sent mailbox open.\n", "sendPacket", 2;
}

sub sendMailRead {
	my ($self, $mailID) = @_;
	my $msg = pack('v V', 0x0241, $mailID);
	$self->sendToServer($msg);
	debug "Sent read mail.\n", "sendPacket", 2;
}

sub sendMailDelete {
	my ($self, $mailID) = @_;
	my $msg = pack('v V', 0x0243, $mailID);
	$self->sendToServer($msg);
	debug "Sent delete mail.\n", "sendPacket", 2;
}

sub sendMailGetAttach {
	my ($self, $mailID) = @_;
	my $msg = pack('v V', 0x0244, $mailID);
	$self->sendToServer($msg);
	debug "Sent mail get attachment.\n", "sendPacket", 2;
}

sub sendMailOperateWindow {
	my ($self, $window) = @_;
	my $msg = pack('v C x', 0x0246, $window);
	$self->sendToServer($msg);
	debug "Sent mail window.\n", "sendPacket", 2;
}

sub sendMailSetAttach {
	my $self = $_[0];
	my $amount = $_[1];
	my $index = (defined $_[2]) ? $_[2] : 0;	# 0 for zeny
	my $msg = pack('v2 V', 0x0247, $index, $amount);
	$self->sendToServer($msg);
	debug "Sent mail set attachment.\n", "sendPacket", 2;
}

sub sendMailSend {
	my ($self, $receiver, $title, $message) = @_;
	my $msg = pack('v2 Z24 a40 C Z*', 0x0248, length($message)+70 , stringToBytes($receiver), stringToBytes($title), length($message), stringToBytes($message));
	$self->sendToServer($msg);
	debug "Sent mail send.\n", "sendPacket", 2;
}

sub sendAuctionAddItem {
	my ($self, $index, $amount) = @_;
	my $msg = pack('v2 V', 0x024C, $index, $amount);
	$self->sendToServer($msg);
	debug "Sent Auction Add Item.\n", "sendPacket", 2;
}

sub sendAuctionCancel {
	my ($self, $id) = @_;
	my $msg = pack('v V', 0x024E, $id);
	$self->sendToServer($msg);
	debug "Sent Auction Cancel.\n", "sendPacket", 2;
}

sub sendAuctionBuy {
	my ($self, $id, $bid) = @_;
	my $msg = pack('v V2', 0x024F, $id, $bid);
	$self->sendToServer($msg);
	debug "Sent Auction Buy.\n", "sendPacket", 2;
}

1;

=pod
//2005-07-18aSakexe
packet_ver: 18
0x0072,19,useskilltoid,5:11:15
0x007e,110,useskilltoposinfo,9:15:23:28:30
0x0085,11,changedir,6:10
0x0089,7,ticksend,3
0x008c,11,getcharnamerequest,7
0x0094,21,movetokafra,12:17
0x009b,31,wanttoconnection,3:13:22:26:30
0x009f,12,useitem,3:8
0x00a2,18,solvecharname,14
0x00a7,15,walktoxy,12
0x00f5,7,takeitem,3
0x00f7,13,movefromkafra,5:9
0x0113,30,useskilltopos,9:15:23:28
0x0116,12,dropitem,6:10
0x0190,21,actionrequest,5:20
0x0216,6
0x023f,2,mailrefresh,0
0x0240,8
0x0241,6,mailread,2
0x0242,-1
0x0243,6,maildelete,2
0x0244,6,mailgetattach,2
0x0245,7
0x0246,4,mailwinopen,2
0x0247,8,mailsetattach,2:4
0x0248,68
0x0249,3
0x024a,70
0x024b,4,auctioncancelreg,0
0x024c,8,auctionsetitem,0
0x024d,14
0x024e,6,auctioncancel,0
0x024f,10,auctionbid,0
0x0250,3
0x0251,2
0x0252,-1
=cut