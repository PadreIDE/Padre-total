package Padre::Plugin::Moose::Method;

use namespace::clean;
use Moose;

our $VERSION = '0.07';

with 'Padre::Plugin::Moose::CanGenerateCode';
with 'Padre::Plugin::Moose::CanProvideHelp';

has 'name' => ( is => 'rw', isa => 'Str' );

sub generate_code {
	return "sub " . $_[0]->name . " { }\n";
}

sub provide_help {
	require Wx;
	return Wx::gettext('A method is a subroutine within a class that defines behavior at runtime');
}

__PACKAGE__->meta->make_immutable;

1;
