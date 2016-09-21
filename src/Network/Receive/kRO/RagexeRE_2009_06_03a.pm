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

package Network::Receive::kRO::RagexeRE_2009_06_03a;

use strict;
use base qw(Network::Receive::kRO::RagexeRE_2009_05_20a);

sub new {
	my ($class) = @_;
	my $self = $class->SUPER::new(@_);
	my %packets = (
		# 0x07d7 is sent packet
		'07D8' => ['party_exp', 'V C2', [qw(type item_pickup item_division)]], # 8 # TODO: add last 2 to the function
		'07D9' => ['hotkeys'], # 254 # hotkeys:36
		# 0x07da is sent packet
	);

	foreach my $switch (keys %packets) {
		$self->{packet_list}{$switch} = $packets{$switch};
	}

	return $self;
}

1;

=pod
//2009-06-03aRagexeRE
0x07d7,8,partychangeoption,2:6
0x07d8,8
0x07d9,254
0x07da,6,partychangeleader,2
=cut