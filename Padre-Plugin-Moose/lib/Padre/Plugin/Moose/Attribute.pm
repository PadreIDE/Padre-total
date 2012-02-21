package Padre::Plugin::Moose::Attribute;

use namespace::clean;
use Moose;

has 'name'     => ( is => 'rw', isa => 'Str' );
has 'type'     => ( is => 'rw', isa => 'Str' );
has 'access'   => ( is => 'rw', isa => 'Str' );
has 'trigger'  => ( is => 'rw', isa => 'Str' );
has 'required' => ( is => 'rw', isa => 'Bool' );

sub to_code {
	my $self = shift;
	my $comment = shift;

	my $code = '';

	return $code;
}

__PACKAGE__->meta->make_immutable;

1;
