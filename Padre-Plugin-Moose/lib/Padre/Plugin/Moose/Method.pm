package Padre::Plugin::Moose::Method;

use namespace::clean;
use Moose;

our $VERSION = '0.08';

extends 'Padre::Plugin::Moose::ClassMember';

with 'Padre::Plugin::Moose::Role::CanGenerateCode';
with 'Padre::Plugin::Moose::Role::CanProvideHelp';
with 'Padre::Plugin::Moose::Role::CanHandleInspector';

sub generate_code {
	return "sub " . $_[0]->name . " {\n\tmy \$self = shift;\n}\n";
}

sub provide_help {
	require Wx;
	return Wx::gettext('A method is a subroutine within a class that defines behavior at runtime');
}

sub read_from_inspector {
	$_[0]->name( $_[1]->GetCellValue( 0, 1 ) );
}

sub write_to_inspector {
	$_[1]->SetCellValue( 0, 1, $_[0]->name );
}

sub get_grid_data {
	require Wx;
	return [ { name => Wx::gettext('Name:') } ];
}

__PACKAGE__->meta->make_immutable;

1;
