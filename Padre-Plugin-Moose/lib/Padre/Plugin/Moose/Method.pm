package Padre::Plugin::Moose::Method;

use namespace::clean;
use Moose;

our $VERSION = '0.08';

with 'Padre::Plugin::Moose::Role::CanGenerateCode';
with 'Padre::Plugin::Moose::Role::CanProvideHelp';
with 'Padre::Plugin::Moose::Role::CanHandleInspector';

has 'name' => ( is => 'rw', isa => 'Str' );

sub generate_code {
	return "sub " . $_[0]->name . " {\n\tmy \$self = shift;\n}\n";
}

sub provide_help {
	require Wx;
	return Wx::gettext('A method is a subroutine within a class that defines behavior at runtime');
}

sub read_from_inspector {
}

sub write_to_inspector {
}

__PACKAGE__->meta->make_immutable;

1;
