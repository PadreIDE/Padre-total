package Padre::Plugin::Moose::ClassMember;

use Moose;
use namespace::clean;

has 'name' => ( is => 'rw', isa => 'Str' );

__PACKAGE__->meta->make_immutable;

1;

