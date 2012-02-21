package Padre::Plugin::Moose::Code;

use namespace::clean;
use Moose;

has 'name'          => ( is => 'rw', isa => 'Str' );
has 'constraint'    => ( is => 'rw', isa => 'Str' );
has 'error_message' => ( is => 'rw', isa => 'Str' );

sub to_code {
	my $self = shift;
	my $comment = shift;

	my $code = '';

	return $code;
}

__PACKAGE__->meta->make_immutable;

1;
