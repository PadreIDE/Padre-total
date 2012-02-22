package Padre::Plugin::Moose::Method;

use namespace::clean;
use Moose;

with 'Padre::Plugin::Moose::CodeGen';

has 'name' => ( is => 'rw', isa => 'Str' );

sub to_code {
	return "sub " . $_[0]->name . " { }\n";
}

__PACKAGE__->meta->make_immutable;

1;
