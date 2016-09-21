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
#
#  $Revision: 6687 $
#  $Id: kRO.pm 6687 2009-04-19 19:04:25Z technologyguild $
########################################################################
# Korea (kRO)
# The majority of private servers use eAthena, this is a clone of kRO

package Network::Receive::kRO::RagexeRE_2009_10_06a;

use strict;
use base qw(Network::Receive::kRO::RagexeRE_2009_09_29a);

sub new {
	my ($class) = @_;
	my $self = $class->SUPER::new(@_);
	my %packets = (
		# //0x07ec,8
		# //0x07ed,10
		# //0x07f0,8
		# //0x07f1,15
		# //0x07f2,6
		# //0x07f3,4
		# //0x07f4,3
	);

	foreach my $switch (keys %packets) {
		$self->{packet_list}{$switch} = $packets{$switch};
	}

	return $self;
}

1;

=pod
//2009-10-06aRagexeRE
//0x07ec,8
//0x07ed,10
//0x07f0,8
//0x07f1,15
//0x07f2,6
//0x07f3,4
//0x07f4,3
=cut