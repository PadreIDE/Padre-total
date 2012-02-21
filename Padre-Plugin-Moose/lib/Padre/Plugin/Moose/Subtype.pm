package Padre::Plugin::Moose::Code;

use namespace::clean;
use Moose;

has 'name'          => ( is => 'rw', isa => 'Str' );
has 'constraint'    => ( is => 'rw', isa => 'Str' );
has 'error_message' => ( is => 'rw', isa => 'Str' );

__PACKAGE__->meta->make_immutable;

1;
