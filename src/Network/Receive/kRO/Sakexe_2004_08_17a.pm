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

package Network::Receive::kRO::Sakexe_2004_08_17a;

use strict;
use base qw(Network::Receive::kRO::Sakexe_2004_08_16a);

sub new {
	my ($class) = @_;
	my $self = $class->SUPER::new(@_);
		
	my %packets = (
		# 0x020f is sent packet
		'0210' => ['pvppoint_result', 'a4 a4 V3', [qw(ID guildID win_point lose_point point)]], # 22
	);
	
	foreach my $switch (keys %packets) {
		$self->{packet_list}{$switch} = $packets{$switch};
	}

	return $self;
}

=pod
//2004-08-17aSakexe
0x020f,10
0x0210,22
=cut

1;