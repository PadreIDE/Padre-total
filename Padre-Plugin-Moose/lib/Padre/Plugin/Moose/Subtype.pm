package Padre::Plugin::Moose::Subtype;

use namespace::clean;
use Moose;

our $VERSION = '0.08';

with 'Padre::Plugin::Moose::Role::CanGenerateCode';
with 'Padre::Plugin::Moose::Role::CanProvideHelp';
with 'Padre::Plugin::Moose::Role::CanHandleInspector';

has 'name'          => ( is => 'rw', isa => 'Str' );
has 'base_type'     => ( is => 'rw', isa => 'Str', default => '' );
has 'constraint'    => ( is => 'rw', isa => 'Str', default => '' );
has 'error_message' => ( is => 'rw', isa => 'Str', default => '' );

sub generate_code {
	my $self = shift;

	my $code = "subtype '" . $self->name . "'";
	$code .= ",\n\tas '" . $self->base_type . "'";
	$code .= ",\n\twhere { " . $self->constraint . " }"
		if ( defined $self->constraint )
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
}

sub write_to_inspector {
}

__PACKAGE__->meta->make_immutable;

1;
