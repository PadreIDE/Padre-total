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
		$code .= $class->to_code($comments);
	}

	if($sample_code) {
		$code .= "\npackage main;\n";
		my $count = 1;
		for my $class (@{$self->classes}) {
			$code .= "\nmy \$o$count = " . $class->name . "->new;\n";
			$count++;
		}
	}
s
	return $code;
}

__PACKAGE__->meta->make_immutable;

1;
