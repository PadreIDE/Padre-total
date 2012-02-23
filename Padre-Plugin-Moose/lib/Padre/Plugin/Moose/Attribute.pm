package Padre::Plugin::Moose::Attribute;

use Moose;
use namespace::clean;

our $VERSION = '0.08';

with 'Padre::Plugin::Moose::CanGenerateCode';
with 'Padre::Plugin::Moose::CanProvideHelp';
with 'Padre::Plugin::Moose::CanHandleInspector';

has 'name'        => ( is => 'rw', isa => 'Str' );
has 'access_type' => ( is => 'rw', isa => 'Str', default => 'rw' );
has 'type'        => ( is => 'rw', isa => 'Str' );
has 'trigger'     => ( is => 'rw', isa => 'Str' );
has 'required'    => ( is => 'rw', isa => 'Bool' );

sub generate_code {
	my $self    = shift;
	my $comment = shift;

	my $code = '';

	$code = "has '" . $self->name . "' => (\n";
	$code .= ( "    is  => '" . $self->access_type . "',\n" ) if defined $self->access_type;
	$code .= ( "    isa => '" . $self->type . "',\n" )        if defined $self->type;
	$code .= ( "    trigger => " . $self->trigger . ",\n" )   if $self->trigger;
	$code .= ("    required => 1,\n")                         if $self->required;
	$code .= ");\n";

	return $code;
}

sub provide_help {
	require Wx;
	return Wx::gettext('An attribute is a property that every member of a class has.');
}

__PACKAGE__->meta->make_immutable;

1;
