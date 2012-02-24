package Padre::Plugin::Moose::Subtype;

use namespace::clean;
use Moose;

our $VERSION = '0.09';

extends 'Padre::Plugin::Moose::ClassMember';

with 'Padre::Plugin::Moose::Role::CanGenerateCode';
with 'Padre::Plugin::Moose::Role::CanProvideHelp';
with 'Padre::Plugin::Moose::Role::CanHandleInspector';

has 'base_type'     => ( is => 'rw', isa => 'Str', default => '' );
has 'constraint'    => ( is => 'rw', isa => 'Str', default => '' );
has 'error_message' => ( is => 'rw', isa => 'Str', default => '' );

sub generate_code {
	my $self = shift;

	my $code = "subtype '" . $self->name . "'";
	$code .= ",\n\tas '" . $self->base_type . "'" if defined $self->base_type && $self->base_type ne '';
	$code .= ",\n\twhere { " . $self->constraint . " }"
		if ( defined $self->constraint && $self->constraint ne '' )
		and $self->constraint ne '';
	$code .= ",\n\tmessage { \"" . $self->error_message . "\" }"
		if ( defined $self->error_message )
		and $self->error_message ne '';
	$code .= ";\n";

	return $code;
}

sub provide_help {
	require Wx;
	return Wx::gettext(
		'A subtype provides the ability to create custom type constraints to be used in attribute definition.');
}

sub read_from_inspector {
	my $self = shift;
	my $grid = shift;

	my $row = 0;
	for my $field (qw(name base_type constraint error_message)) {
		$self->$field( $grid->GetCellValue( $row++, 1 ) );
	}
}

sub write_to_inspector {
	my $self = shift;
	my $grid = shift;

	my $row = 0;
	for my $field (qw(name base_type constraint error_message)) {
		$grid->SetCellValue( $row++, 1, $self->$field );
	}
}

sub get_grid_data {
	require Wx;
	return [
		{ name => Wx::gettext('Name:') },
		{ name => Wx::gettext('Base type:') },
		{ name => Wx::gettext('Constraint:') },
		{ name => Wx::gettext('Error message:') },
	];
}

__PACKAGE__->meta->make_immutable;

1;
