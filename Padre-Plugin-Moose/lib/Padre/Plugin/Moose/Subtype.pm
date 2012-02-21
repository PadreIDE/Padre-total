package Padre::Plugin::Moose::Code;

use namespace::clean;
use Moose;

has 'name';
has 'constraint';
has 'error_message';

__PACKAGE__->meta->make_immutable;

1;
