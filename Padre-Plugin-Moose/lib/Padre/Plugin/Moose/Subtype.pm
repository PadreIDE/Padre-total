package Padre::Plugin::Moose::Subtype;

use namespace::clean;
use Moose;

our $VERSION = '0.06';

with 'Padre::Plugin::Moose::CanGenerateCode';
with 'Padre::Plugin::Moose::CanProvideHelp';

has 'name'          => ( is => 'rw', isa => 'Str' );
has 'constraint'    => ( is => 'rw', isa => 'Str', default => '' );
has 'error_message' => ( is => 'rw', isa => 'Str', default => '' );

sub generate_code {
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

sub provide_help {
	require Wx;
	return Wx::gettext('A subtype provides the ability to create custom type constraints to be used in attribute definition.');
}

__PACKAGE__->meta->make_immutable;

1;
