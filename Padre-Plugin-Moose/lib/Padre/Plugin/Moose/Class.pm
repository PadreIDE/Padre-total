package Padre::Plugin::Moose::Class;

use namespace::clean;
use Moose;

has 'name';
has 'extends_classes';
has 'with_roles';
has 'attributes';
has 'subtypes';

__PACKAGE__->meta->make_immutable;

1;