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

package Network::Send::kRO::RagexeRE_2010_03_09a;

use strict;
use base qw(Network::Send::kRO::RagexeRE_2010_03_03a);

sub new {
	my ($class) = @_;
	return $class->SUPER::new(@_);
}

=pod
//2010-03-09aRagexeRE
//0x0813,-1
//0x0814,2
//0x0815,6
//0x0816,6
//0x0818,-1
//0x0819,10
//0x081A,4
//0x081B,4
//0x081C,6
//0x081D,22
//0x081E,8
=cut

1;