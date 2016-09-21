#########################################################################
#  OpenKore - Network subsystem
#  Copyright (c) 2006 OpenKore Team
#
#  This software is open source, licensed under the GNU General Public
#  License, version 2.
#  Basically, this means that you're allowed to modify and distribute
#  this software. However, if you distribute modified versions, you MUST
#  also distribute the source code.
#  See http://www.gnu.org/licenses/gpl.html for the full license.
#########################################################################
# iRO (International) as of June 21 2007.
# Servertype overview: http://wiki.openkore.com/index.php/ServerType
package Network::Receive::ServerType18;

use strict;
use Network::Receive::ServerType0 ();
use base qw(Network::Receive::ServerType0);
use Log qw(message warning error debug);
use AI;
use Translation;
use Globals;
use I18N qw(bytesToString);
use Utils qw(getHex swrite makeIP makeCoordsDir makeCoordsXY makeCoordsFromTo);
 
sub new {
	my ($class) = @_;
	my $self = $class->SUPER::new;
	return $self;
}

1;
