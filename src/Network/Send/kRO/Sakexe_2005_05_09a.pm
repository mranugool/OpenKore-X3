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

package Network::Send::kRO::Sakexe_2005_05_09a;

use strict;
use base qw(Network::Send::kRO::Sakexe_2005_04_25a);

use Log qw(debug);

sub version {
	return 16;
}

sub new {
	my ($class) = @_;
	my $self = $class->SUPER::new(@_);
	
	my %packets = (
		'0072' => ['skill_use', 'x4 V v x9 a4', [qw(lv skillID targetID)]],#25
		'0085' => ['actor_look_at', 'x5 v x C', [qw(head body)]],
		'0089' => ['sync', 'x2 V', [qw(time)]],
		'008C' => ['actor_info_request', 'x5 a4', [qw(ID)]],
		'0094' => ['storage_item_add', 'x5 v x V', [qw(index amount)]],
		'009B' => ['map_login', 'x2 a4 x a4 x4 a4 V C', [qw(accountID charID sessionID tick sex)]],
		'009F' => ['item_use', 'x2 v x4 a4', [qw(index targetID)]],#14
		'00A2' => ['actor_name_request', 'x9 a4', [qw(ID)]],
		'00A7' => ['character_move', 'x3 a3', [qw(coords)]],
		'00F5' => ['item_take', 'x2 a4', [qw(ID)]],
		'00F7' => ['storage_item_remove', 'x12 v x2 V', [qw(index amount)]],
		'0113' => ['skill_use_location', 'x3 v x2 v x v x6 v', [qw(lv skillID x y)]],
		'0116' => ['item_drop', 'x3 v x v', [qw(index amount)]],
		'0190' => ['actor_action', 'x3 a4 x9 C', [qw(targetID type)]],
	);
	$self->{packet_list}{$_} = $packets{$_} for keys %packets;
	
	$self;
}

sub sendSkillUseLocInfo {
	my ($self, $ID, $lv, $x, $y, $moreinfo) = @_;
	my $msg = pack('v x3 v x2 v x v x6 v Z80', 0x007E, $lv, $ID, $x, $y, $moreinfo);
	$self->sendToServer($msg);
	debug "Skill Use on Location: $ID, ($x, $y)\n", "sendPacket", 2;
}

1;

=pod
//2005-05-09aSakexe
packet_ver: 16
0x0072,25,useskilltoid,6:10:21
0x007e,102,useskilltoposinfo,5:9:12:20:22
0x0085,11,changedir,7:10
0x0089,8,ticksend,4
0x008c,11,getcharnamerequest,7
0x0094,14,movetokafra,7:10
0x009b,26,wanttoconnection,4:9:17:18:25
0x009f,14,useitem,4:10
0x00a2,15,solvecharname,11
0x00a7,8,walktoxy,5
0x00f5,8,takeitem,4
0x00f7,22,movefromkafra,14:18
0x0113,22,useskilltopos,5:9:12:20
0x0116,10,dropitem,5:8
0x0190,19,actionrequest,5:18
=cut