package Padre::Plugin::Moose::Program;

use namespace::clean;
use Moose;

has 'roles'   => ( is => 'rw', isa => 'ArrayRef', default => sub { [] } );
has 'classes' => ( is => 'rw', isa => 'ArrayRef', default => sub { [] } );

sub to_code {
	my $self = shift;
	my $comments = shift;
	my $sample_code = shift;

	my $code = '';
	for my $class (@{$self->classes}) {
		$code .= $class->to_code($comments, $code);
	}
	return $code;
}

__PACKAGE__->meta->make_immutable;

1;
