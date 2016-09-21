#########################################################################
#  OpenKore - Network subsystem
#  This module contains functions for sending messages to the server.
#
#  This software is open source, licensed under the GNU General Public
#  License, version 2.
#  Basically, this means that you're allowed to modify and distribute
#  this software. However, if you distribute modified versions, you MUST
#  also distribute the source code.
#  See http://www.gnu.org/licenses/gpl.html for the full license.
#########################################################################
# idRO (Indonesia)
# Servertype overview: http://wiki.openkore.com/index.php/ServerType
package Network::Send::idRO;

use strict;
use Globals;
use Network::Send::ServerType0;
use base qw(Network::Send::ServerType0);
use Log qw(error debug);
use I18N qw(stringToBytes);
use Utils qw(getTickCount getHex getCoordString);

sub new {
	my ($class) = @_;
	my $self = $class->SUPER::new(@_);

	my %packets = (
		'098f' => ['char_delete2_accept', 'v a4 a*', [qw(length charID code)]],
	);

	foreach my $switch (keys %packets) {
		$self->{packet_list}{$switch} = $packets{$switch};
	}

	my %handlers = qw(
		send_equip 00A9
		storage_password 023B
		sync 0360
		character_move 035F
		actor_info_request 0368
		actor_look_at 0361
		item_take 0362
		item_drop 0363
		storage_item_add 0364
		storage_item_remove 0365
		skill_use_location 0366
		party_setting 07D7
		buy_bulk_vender 0801
		char_delete2_accept 098f
	);
	$self->{packet_lut}{$_} = $handlers{$_} for keys %handlers;
	
	return $self;
}

sub reconstruct_char_delete2_accept {
	my ($self, $args) = @_;
	# length = [packet:2] + [length:2] + [charid:4] + [code_length]
	$args->{length} = 8 + length($args->{code});
	debug "Sent sendCharDelete2Accept. CharID: $args->{CharID}, Code: $args->{code}, Length: $args->{length}\n", "sendPacket", 2;
}

1;
