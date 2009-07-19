package Padre::Swarm::Message::Diff;
use base qw( Class::Accessor );

use strict;
use warnings;
__PACKAGE__->mk_accessors(qw(file project project_dir diff comment));

1;
