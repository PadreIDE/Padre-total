package Padre::Plugin::Moose::Role::HasClassMembers;

use Moose::Role;
use namespace::clean;

our $VERSION = '0.12';

has 'attributes' => ( is => 'rw', isa => 'ArrayRef', default => sub { [] } );
has 'subtypes'   => ( is => 'rw', isa => 'ArrayRef', default => sub { [] } );
has 'methods'    => ( is => 'rw', isa => 'ArrayRef', default => sub { [] } );

sub to_class_members_code {
	my $self     = shift;
	my $comments = shift;

	my $code = '';

	# Generate attributes
	$code .= "\n" if scalar @{ $self->attributes };
	for my $attribute ( @{ $self->attributes } ) {
		$code .= $attribute->generate_code($comments);
	}

	# Generate subtypes
	$code .= "\n" if scalar @{ $self->subtypes };
	for my $subtype ( @{ $self->subtypes } ) {
		$code .= $subtype->generate_code($comments);
	}

	# Generate methods
	$code .= "\n" if scalar @{ $self->methods };
	for my $method ( @{ $self->methods } ) {
		$code .= $method->generate_code($comments);
	}

	return $code;
}

1;

__END__

=pod

=head1 NAME

Padre::Plugin::Moose::Role::HasClassMembers - Something that has attributes, subtypes and methods

=cut
