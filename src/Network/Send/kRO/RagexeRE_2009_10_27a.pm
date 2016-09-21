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

package Network::Send::kRO::RagexeRE_2009_10_27a;

use strict;
use base qw(Network::Send::kRO::RagexeRE_2009_10_06a);

use Log qw(debug);

sub new {
	my ($class) = @_;
	return $class->SUPER::new(@_);
}

# 0x07f5,6,gmreqaccname,2
sub sendGMReqAccName {
	my ($self, $targetID) = @_;
	my $msg = pack('v V', 0x07F5, $targetID);
	$self->sendToServer($msg);
	debug "Sent GM Request Account Name.\n", "sendPacket", 2;
}

=pod
//2009-10-27aRagexeRE
0x07f5,6
0x07f6,14
=cut

1;