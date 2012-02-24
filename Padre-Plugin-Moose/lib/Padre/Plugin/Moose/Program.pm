package Padre::Plugin::Moose::Program;

use namespace::clean;
use Moose;

our $VERSION = '0.11';

with 'Padre::Plugin::Moose::Role::CanGenerateCode';
with 'Padre::Plugin::Moose::Role::CanProvideHelp';

has 'roles'   => ( is => 'rw', isa => 'ArrayRef', default => sub { [] } );
has 'classes' => ( is => 'rw', isa => 'ArrayRef', default => sub { [] } );

sub generate_code {
	my $self        = shift;
	my $comments    = shift;
	my $sample_code = shift;

	my $code = '';

	# Generate roles
	for my $role ( @{ $self->roles } ) {
		$code .= $role->generate_code($comments);
	}

	# Generate classes
	for my $class ( @{ $self->classes } ) {
		$code .= $class->generate_code($comments);
	}

	# Generate sample usage code
	if ($sample_code) {
		$code .= "\npackage main;\n";
		my $count = 1;
		for my $class ( @{ $self->classes } ) {
			$code .= "my \$o$count = " . $class->name . "->new;\n";
			$count++;
		}
	}

	return $code;
}

sub provide_help {
	require Wx;
	return Wx::gettext('A program can contain multiple class, role definitions');
}

__PACKAGE__->meta->make_immutable;

1;
