#  kRO Client 2008-3-26 (eA packet version 9)
# Servertype overview: http://wiki.openkore.com/index.php/ServerType
package Network::Receive::ServerType8_4;

use strict;
use Network::Receive::ServerType0 ();
use base qw(Network::Receive::ServerType0);
use Globals qw($masterServer);

sub new {
	my ($class) = @_;
	my $self = $class->SUPER::new;
	
	$self->{packet_list}{'0078'} = ['actor_exists', 'x a4 v14 a4 a2 v2 C2 a3 C3 v', [qw(ID walk_speed opt1 opt2 option type hair_style weapon lowhead shield tophead midhead hair_color clothes_color head_dir guildID emblemID manner opt3 stance sex coords unknown1 unknown2 act lv)]]; #standing
	$self->{packet_list}{'007C'} = ['actor_connected', 'x a4 v14 C2 a3 C2', [qw(ID walk_speed opt1 opt2 option hair_style weapon lowhead type shield tophead midhead hair_color clothes_color head_dir stance sex coords unknown1 unknown2)]]; #spawning
	$self->{packet_list}{'022C'} = ['actor_moved', 'x a4 v3 V v5 V v5 a4 a2 v V C2 a6 C2 v', [qw(ID walk_speed opt1 opt2 option type hair_style weapon shield lowhead tick tophead midhead hair_color clothes_color head_dir guildID emblemID manner opt3 stance sex coords unknown1 unknown2 lv)]]; # walking

	return $self;
}

# Overrided method.
sub received_characters_blockSize {
	if ($masterServer && $masterServer->{charBlockSize}) {
		return $masterServer->{charBlockSize};
	} else {
		return 108;
	}
}

1;
