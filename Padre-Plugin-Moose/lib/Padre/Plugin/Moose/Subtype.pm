package Padre::Plugin::Moose::Subtype;

use namespace::clean;
use Moose;

our $VERSION = '0.06';

with 'Padre::Plugin::Moose::CodeGen';

has 'name'          => ( is => 'rw', isa => 'Str' );
has 'constraint'    => ( is => 'rw', isa => 'Str', default => '' );
has 'error_message' => ( is => 'rw', isa => 'Str', default => '' );

sub to_code {
	my $self = shift;

	my $code
		.= "subtype '"
		. $self->name
		. "'\n=> as 'Str'"
		. "\n=> where { "
		. $self->constraint
		. " } => "
		. "\nmessage { "
		. $self->error_message . " };\n";

	return $code;
}

sub help_string {
	require Wx;
	return Wx::gettext('A subtype provides the ability to create custom type constraints to be used in attribute definition.');
}

__PACKAGE__->meta->make_immutable;

1;
