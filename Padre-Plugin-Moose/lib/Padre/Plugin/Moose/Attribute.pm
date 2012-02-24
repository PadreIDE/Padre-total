package Padre::Plugin::Moose::Attribute;

use Moose;
use namespace::clean;

our $VERSION = '0.09';

extends 'Padre::Plugin::Moose::ClassMember';

with 'Padre::Plugin::Moose::Role::CanGenerateCode';
with 'Padre::Plugin::Moose::Role::CanProvideHelp';
with 'Padre::Plugin::Moose::Role::CanHandleInspector';

has 'access_type' => ( is => 'rw', isa => 'Str' );
has 'type'        => ( is => 'rw', isa => 'Str' );
has 'trigger'     => ( is => 'rw', isa => 'Str' );
has 'required'    => ( is => 'rw', isa => 'Bool' );

sub generate_code {
	my $self    = shift;
	my $comment = shift;

	my $has_code = '';
	$has_code .= ( "\tis  => '" . $self->access_type . "',\n" )
		if defined $self->access_type && $self->access_type ne '';
	$has_code .= ( "\tisa => '" . $self->type . "',\n" )      if defined $self->type    && $self->type    ne '';
	$has_code .= ("\trequired => 1,\n")                       if $self->required;
	$has_code .= ( "\ttrigger => " . $self->trigger . ",\n" ) if defined $self->trigger && $self->trigger ne '';

	return "has '" . $self->name . "'" . ( $has_code ne '' ? qq{ => (\n$has_code)} : q{} ) . ";\n";
}

sub provide_help {
	require Wx;
	return Wx::gettext('An attribute is a property that every member of a class has.');
}

sub read_from_inspector {
	my $self = shift;
	my $grid = shift;

	my $row = 0;
	for my $field (qw(name access_type type required trigger)) {
		$self->$field( $grid->GetCellValue( $row++, 1 ) );
	}
}

sub write_to_inspector {
	my $self = shift;
	my $grid = shift;

	my $row = 0;
	for my $field (qw(name type access_type trigger required)) {
		$grid->SetCellValue( $row++, 1, $self->$field );
	}
}

sub get_grid_data {
	require Wx;
	return [
		{ name => Wx::gettext('Name:') },
		{ name => Wx::gettext('Access type:') },
		{ name => Wx::gettext('Type:') },
		{ name => Wx::gettext('Required:'), is_bool => 1 },
		{ name => Wx::gettext('Trigger:') },
	];
}

__PACKAGE__->meta->make_immutable;

1;
