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

package Network::Receive::kRO::RagexeRE_2012_05_15a;

use strict;
use base qw(Network::Receive::kRO::RagexeRE_2012_04_10a);

1;

=pod
//2012-05-15aRagexeRE
0x01FD,15,repairitem,2
0x0369,26,friendslistadd,2
0x094B,5,hommenu,2:4
0x089A,36,storagepassword,0
0x0288,-1,cashshopbuy,4:8
0x091F,26,partyinvite2,2
0x08A8,19,wanttoconnection,2:6:10:14:18
0x0923,7,actionrequest,2:6
0x0947,10,useskilltoid,2:4:6
0x0439,8,useitem,2:4
0x0366,-1,itemlistwindowselected,2:4:8
0x0891,-1,reqopenbuyingstore,2:4:8:9:89
0x092C,2,reqclosebuyingstore,0
0x091A,6,reqclickbuyingstore,2
0x096A,-1,reqtradebuyingstore,2:4:8:12
0x0817,-1,searchstoreinfo,2:4:5:9:13:14:15
0x0367,2,searchstoreinfonextpage,0
0x087E,12,searchstoreinfolistitemclick,2:6:10
0x087C,5,walktoxy,2
0x087D,6,ticksend,2
0x08AC,5,changedir,2:4
0x0964,6,takeitem,2
0x0364,6,dropitem,2:4
0x085A,8,movetokafra,2:4
0x0869,8,movefromkafra,2:4
0x08AD,10,useskilltopos,2:4:6:8
0x08A2,90,useskilltoposinfo,2:4:6:8:10
0x08A5,6,getcharnamerequest,2
0x0957,6,solvecharname,2
0x08E5,41,bookingregreq,2:4	//Added to prevent disconnections
0x08E6,4
0x08E7,10,bookingsearchreq,2
0x08E8,-1
0x08E9,2,bookingdelreq,2
0x08EA,4
0x08EB,39,bookingupdatereq,2
0x08EC,73
0x08ED,43
0x08EE,6
0x08EF,6,bookingignorereq,2
0x08F0,6
0x08F1,6,bookingjoinpartyreq,2
0x08F2,36
0x08F3,-1
0x08F4,6
0x08F5,-1,bookingsummonmember,2:4
0x08F6,22
0x08F7,3
0x08F8,7
0x08F9,6
0x08FA,6
0x08FB,6,bookingcanceljoinparty,2
0x0907,5,moveitem,2:4
0x0908,5
0x08D7,28,battlegroundreg,2:4 //Added to prevent disconnections
=cut