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

package Network::Receive::kRO::RagexeRE_2009_12_22a;

use strict;
use base qw(Network::Receive::kRO::RagexeRE_2009_12_08a);

sub new {
	my ($class) = @_;
	my $self = $class->SUPER::new(@_);
	my %packets = (
		#//0x0802,18
		#//0x0803,4
		#//0x0804,8
		#//0x0805,0
		#//0x0806,4
		#//0x0807,2
		#//0x0808,4
		#//0x0809,14
		#//0x080a,50
		#//0x080b,18
		#//0x080c,6
	);

	foreach my $switch (keys %packets) {
		$self->{packet_list}{$switch} = $packets{$switch};
	}

	return $self;
}

1;

=pod
#//2009-12-22aRagexeRE
//0x0802,18
//0x0803,4
//0x0804,8
//0x0805,0
//0x0806,4
//0x0807,2
//0x0808,4
//0x0809,14
//0x080a,50
//0x080b,18
//0x080c,6
=cut