package Padre::Plugin::Moose::Role;

use namespace::clean;
use Moose;

has 'name'          => ( is => 'rw', isa => 'Str' );
has 'requires_list' => ( is => 'rw', isa => 'Str' );

__PACKAGE__->meta->make_immutable;

1;
