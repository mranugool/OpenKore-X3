# pRO Thor as of October 22 2006
# Servertype overview: http://wiki.openkore.com/index.php/ServerType
package Network::Receive::ServerType12;

use strict;
use base qw(Network::Receive::ServerType0);

sub new {
	my ($class) = @_;
	my $self = $class->SUPER::new;
	return $self;
}

1;
