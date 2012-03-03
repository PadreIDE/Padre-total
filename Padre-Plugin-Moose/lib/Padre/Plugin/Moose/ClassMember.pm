package Padre::Plugin::Moose::ClassMember;

use Moose;
use namespace::clean;

our $VERSION = '0.18';

has 'name' => ( is => 'rw', isa => 'Str' );

__PACKAGE__->meta->make_immutable;

1;

