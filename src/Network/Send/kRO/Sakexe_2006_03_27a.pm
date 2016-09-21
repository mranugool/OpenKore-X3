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

package Network::Send::kRO::Sakexe_2006_03_27a;

use strict;
use base qw(Network::Send::kRO::Sakexe_2006_03_13a);

use Log qw(debug);

sub version {
	return 20;
}

sub new {
	my ($class) = @_;
	my $self = $class->SUPER::new(@_);
	
	my %packets = (
		'0072' => ['skill_use', 'x9 V x3 v x2 a4', [qw(lv skillID targetID)]],#26
		'0085' => ['actor_look_at', 'x5 C x3 C', [qw(head body)]],
		# 0089 unchanged
		'008C' => ['actor_info_request', 'x6 a4', [qw(ID)]],
		'0094' => ['storage_item_add', 'x3 v x12 V', [qw(index amount)]],
		'009B' => ['map_login', 'x7 a4 x8 a4 x3 a4 V C', [qw(accountID charID sessionID tick sex)]],
		'009F' => ['item_use', 'x7 v x9 a4', [qw(index targetID)]],#24
		'00A2' => ['actor_name_request', 'x5 a4', [qw(ID)]],
		'00A7' => ['character_move', 'x10 a3', [qw(coords)]],
		# 00F5 unchanged
		'00F7' => ['storage_item_remove', 'x9 v x9 V', [qw(index amount)]],
		'0113' => ['skill_use_location', 'x3 v x8 v x12 v x7 v', [qw(lv skillID x y)]],
		'0116' => ['item_drop', 'x6 v x5 v', [qw(index amount)]],
		'0190' => ['actor_action', 'x5 a4 x6 C', [qw(targetID type)]],
	);
	$self->{packet_list}{$_} = $packets{$_} for keys %packets;
	
	$self;
}

sub sendSkillUseLocInfo {
	my ($self, $ID, $lv, $x, $y, $moreinfo) = @_;
	my $msg = pack('v x3 v x8 v x12 v x7 v Z80', 0x007E, $lv, $ID, $x, $y, $moreinfo);
	$self->sendToServer($msg);
	debug "Skill Use on Location: $ID, ($x, $y)\n", "sendPacket", 2;
}

1;

=pod
//2006-03-27aSakexe
packet_ver: 20
0x0072,26,useskilltoid,11:18:22
0x007e,120,useskilltoposinfo,5:15:29:38:40
0x0085,12,changedir,7:11
//0x0089,13,ticksend,9
0x008c,12,getcharnamerequest,8
0x0094,23,movetokafra,5:19
0x009b,37,wanttoconnection,9:21:28:32:36
0x009f,24,useitem,9:20
0x00a2,11,solvecharname,7
0x00a7,15,walktoxy,12
0x00f5,13,takeitem,9
0x00f7,26,movefromkafra,11:22
0x0113,40,useskilltopos,5:15:29:38
0x0116,17,dropitem,8:15
0x0190,18,actionrequest,7:17
=cut