package Padre::Plugin::Moose::Role;

use namespace::clean;
use Moose;

has 'name';
has 'requires';

__PACKAGE__->meta->make_immutable;

1;