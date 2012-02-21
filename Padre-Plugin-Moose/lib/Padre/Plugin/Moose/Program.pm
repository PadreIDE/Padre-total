package Padre::Plugin::Moose::Program;

use namespace::clean;
use Moose;

has 'roles';
has 'classes';

__PACKAGE__->meta->make_immutable;

1;