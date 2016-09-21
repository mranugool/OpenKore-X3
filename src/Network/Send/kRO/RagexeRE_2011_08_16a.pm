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
########################################################################
package Network::Send::kRO::RagexeRE_2011_08_16a;

use strict;
use base qw(Network::Send::kRO::RagexeRE_2010_12_28a);

sub new {
	my ($class) = @_;
	my $self = $class->SUPER::new(@_);

	my %packets = (
#		'0361' => undef,
		'0202' => ['actor_look_at', 'v C', [qw(head body)]],#5
		'0436' => undef,
		'022D' => ['map_login', 'a4 a4 a4 V C', [qw(accountID charID sessionID tick sex)]],#19
#		'0202' => undef,
		'023B' => ['friend_request', 'a*', [qw(username)]],#26
#		'0360' => undef,
		'035F' => ['sync', 'V', [qw(time)]],#6
#		'0817' => undef,
		'0360' => ['buy_bulk_request', 'a4', [qw(ID)]],#6
#		'022D' => undef,
		'0361' => ['homunculus_command', 'v C', [qw(commandType, commandID)]],#5
		'0363' => undef,
		'0362' => ['item_drop', 'v2', [qw(index amount)]],#6
		'0365' => undef,
		'0364' => ['storage_item_remove', 'v V', [qw(index amount)]],#8
#		'0369' => undef,
		'0368' => ['actor_name_request', 'a4', [qw(ID)]],#6
#		'0437' => undef,
		'0369' => ['actor_action', 'a4 C', [qw(targetID type)]],#7
#		'035F' => undef,
		'0437' => ['character_move', 'a3', [qw(coords)]],#5
		'0366' => undef,
		'0438' => ['skill_use_location', 'v4', [qw(lv skillID x y)]],#10
#		'0362' => undef,
		'07E4' => ['item_take', 'a4', [qw(ID)]],#6
#		'0364' => undef,
		'07EC' => ['storage_item_add', 'v V', [qw(index amount)]],
		'02C4' => undef,
		'0802' => ['party_join_request_by_name', 'Z24', [qw(partyName)]],#26
#		'0438' => undef,
		'083C' => ['skill_use', 'v2 a4', [qw(lv skillID targetID)]],#10
#		'0368' => undef,
		'08AD' => ['actor_info_request', 'a4', [qw(ID)]],#6
#		'08B8' => ['send_pin_password','a4 Z*', [qw(accountID pin)]],#10
		'08BA' => ['new_pin_password','a4 Z*', [qw(accountID pin)]],
#		'0815' => undef,
		'0817' => ['buy_bulk_closeShop'],#2
		'0811' => undef,
		'0815' => ['buy_bulk_openShop', 'a4 c a*', [qw(limitZeny result itemInfo)]],#-1

		);
	$self->{packet_list}{$_} = $packets{$_} for keys %packets;

	my %handlers = qw(
		actor_action 0369
		actor_info_request 08AD
		actor_name_request 0368
		actor_look_at 0202
		buy_bulk_closeShop 0817
		buy_bulk_openShop 0815
		buy_bulk_request 0360
		character_move 0437
		friend_request 023B
		homunculus_command 0361
		item_drop 0362
		item_take 07E4
		map_login 022D
		party_join_request_by_name 0802
		send_pin_password 08B8
		skill_use 083C
		skill_use_location 0438
		storage_item_add 07EC
		storage_item_remove 0364
		sync 035F
	);
	$self->{packet_lut}{$_} = $handlers{$_} for keys %handlers;

	$self;
} 

1;

=cut
//2011-08-16aRagexeRE
0x01FD,15,repairitem,2
+0x023B,26,friendslistadd,2
+0x0361,5,hommenu,2:4
0x088F,36,storagepassword,0
0x0288,-1,cashshopbuy,4:8
+0x0802,26,partyinvite2,2
+0x022D,19,wanttoconnection,2:6:10:14:18
+0x0369,7,actionrequest,2:6
+0x083C,10,useskilltoid,2:4:6
+0x0439,8,useitem,2:4
0x0281,-1,itemlistwindowselected,2:4:8
0x0365,18,bookingregreq,2:4:6
0x0803,4
0x0804,14,bookingsearchreq,2:4:6:8:12
0x0805,-1
0x0806,2,bookingdelreq,0
0x0807,4
0x0808,14,bookingupdatereq,2
0x0809,50
0x080A,18
0x080B,6
+0x0815,-1,reqopenbuyingstore,2:4:8:9:89
+0x0817,2,reqclosebuyingstore,0
+0x0360,6,reqclickbuyingstore,2
0x0811,-1,reqtradebuyingstore,2:4:8:12
0x0819,-1,searchstoreinfo,2:4:5:9:13:14:15
0x0835,2,searchstoreinfonextpage,0
0x0838,12,searchstoreinfolistitemclick,2:6:10
+0x0437,5,walktoxy,2
+0x035F,6,ticksend,2
+0x0202,5,changedir,2:4
+0x07E4,6,takeitem,2
+0x0362,6,dropitem,2:4
+0x07EC,8,movetokafra,2:4
+0x0364,8,movefromkafra,2:4
+0x0438,10,useskilltopos,2:4:6:8
0x0366,90,useskilltoposinfo,2:4:6:8:10
+0x08AD,6,getcharnamerequest,2
+0x0368,6,solvecharname,2 
=pod