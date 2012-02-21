package Padre::Plugin::Moose::Attribute;

use namespace::clean;
use Moose;

has 'name';
has 'type';
has 'property';
has 'trigger';
has 'required';

__PACKAGE__->meta->make_immutable;

1;
