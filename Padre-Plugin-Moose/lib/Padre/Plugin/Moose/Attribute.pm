package Padre::Plugin::Moose::Attribute;

use Moose;
use namespace::clean;

our $VERSION = '0.07';

with 'Padre::Plugin::Moose::CanGenerateCode';
with 'Padre::Plugin::Moose::CanProvideHelp';

has 'name'     => ( is => 'rw', isa => 'Str' );
has 'type'     => ( is => 'rw', isa => 'Str', default => 'Str' );
has 'access'   => ( is => 'rw', isa => 'Str', default => 'rw' );
has 'trigger'  => ( is => 'rw', isa => 'Str' );
has 'required' => ( is => 'rw', isa => 'Bool' );

sub generate_code {
	my $self    = shift;
	my $comment = shift;

	my $code = '';

	$code = "has '" . $self->name . "' => (\n";
	$code .= ( "    is  => '" . $self->access . "',\n" )    if defined $self->access;
	$code .= ( "    isa => '" . $self->type . "',\n" )      if defined $self->type;
	$code .= ( "    trigger => " . $self->trigger . ",\n" ) if $self->trigger;
	$code .= ("    required => 1,\n")                       if $self->required;
	$code .= ");\n";

	return $code;
}

sub provide_help {
	require Wx;
	return Wx::gettext('An attribute is a property that every member of a class has.');
}

__PACKAGE__->meta->make_immutable;

1;
