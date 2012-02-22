package Padre::Plugin::Moose::Program;

use namespace::clean;
use Moose;

with 'Padre::Plugin::Moose::CodeGen';

has 'roles'   => ( is => 'rw', isa => 'ArrayRef', default => sub { [] } );
has 'classes' => ( is => 'rw', isa => 'ArrayRef', default => sub { [] } );

sub to_code {
	my $self = shift;
	my $comments = shift;
	my $sample_code = shift;

	my $code = '';

	# Generate roles
	for my $role (@{$self->roles}) {
		$code .= $role->to_code($comments);
	}

	# Generate classes
	for my $class (@{$self->classes}) {
		$code .= $class->to_code($comments);
	}

	# Generate sample usage code
	if($sample_code) {
		$code .= "\npackage main;\n";
		my $count = 1;
		for my $class (@{$self->classes}) {
			$code .= "my \$o$count = " . $class->name . "->new;\n";
			$count++;
		}
	}

	return $code;
}

__PACKAGE__->meta->make_immutable;

1;
