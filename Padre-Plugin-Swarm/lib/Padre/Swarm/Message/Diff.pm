package Padre::Swarm::Message::Diff;
use Padre::Swarm::Message;

use base qw( Padre::Swarm::Message );

use strict;
use warnings;
__PACKAGE__->mk_accessors(qw(file project project_dir diff comment));

1;
