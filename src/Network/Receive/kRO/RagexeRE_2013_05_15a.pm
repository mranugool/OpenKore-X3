#########################################################################
#  OpenKore - Packet Receiveing
#  This module contains functions for Receiveing packets to the server.
#
#  This software is open source, licensed under the GNU General Public
#  License, version 2.
#  Basically, this means that you're allowed to modify and distribute
#  this software. However, if you distribute modified versions, you MUST
#  also distribute the source code.
#  See http://www.gnu.org/licenses/gpl.html for the full license.
########################################################################
# Korea (kRO)
# The majority of private servers use eAthena, this is a clone of kRO

package Network::Receive::kRO::RagexeRE_2013_05_15a;

use strict;
use base qw(Network::Receive::kRO::RagexeRE_2013_03_20);

1;
=pod
//2013-05-15a Ragexe (Yommy)
//packet_ver: 35
+0x0962,26,friendslistadd,2
+0x0931,5,hommenu,2:4
0x093e,36,storagepassword,2:4:20
+0x0947,26,partyinvite2,2
+0x0943,19,wanttoconnection,2:6:10:14:18
+0x0369,7,actionrequest,2:6
+0x083C,10,useskilltoid,2:4:6
+0x0437,5,walktoxy,2
+0x035F,6,ticksend,2
+0x0362,5,changedir,2:4
+0x08A1,6,takeitem,2
+0x0944,6,dropitem,2:4
+0x0887,8,movetokafra,2:4
+0x08AC,8,movefromkafra,2:4
+0x0438,10,useskilltopos,2:4:6:8
+0x0366,90,useskilltoposinfo,2:4:6:8:10
+0x096A,6,getcharnamerequest,2
+0x0368,6,solvecharname,2
0x0815,-1,reqopenbuyingstore,2:4:8:9:89
0x0817,2,reqclosebuyingstore,0
0x0360,6,reqclickbuyingstore,2
0x0811,-1,reqtradebuyingstore,2:4:8:12
0x0819,-1,searchstoreinfo,2:4:5:9:13:14:15
0x0835,2,searchstoreinfonextpage,0
0x0838,12,searchstoreinfolistitemclick,2:6:10
0x092D,18,bookingregreq,2:4:6
//0x08AA,8 CZ_JOIN_BATTLE_FIELD
0x0963,-1,itemlistwindowselected,2:4:8:12
//0x0862,4 CZ_GANGSI_RANK
=cut