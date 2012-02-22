package Padre::Plugin::Moose::Class;

use Moose;
use namespace::clean;

with 'Padre::Plugin::Moose::CodeGen';

has 'name'         => ( is => 'rw', isa => 'Str', default => '' );
has 'extends_list' => ( is => 'rw', isa => 'Str', default => '' );
has 'roles_list'   => ( is => 'rw', isa => 'Str', default => '' );
has 'attributes'   => ( is => 'rw', isa => 'ArrayRef', default => sub { [] } );
has 'subtypes'     => ( is => 'rw', isa => 'ArrayRef', default => sub { [] }  );
has 'methods'     => ( is => 'rw', isa => 'ArrayRef', default => sub { [] }  );
has 'immutable'    => ( is => 'rw', isa => 'Bool'  );
has 'namespace_autoclean'    => ( is => 'rw', isa => 'Bool'  );

sub to_code {
	my $self = shift;
	my $comments = shift;

	my $class = $self->name;
	my $superclass = $self->extends_list;
	my $roles = $self->roles_list;
	my $namespace_autoclean = $self->namespace_autoclean;
	my $make_immutable = $self->immutable;

	$class =~ s/^\s+|\s+$//g;
	$superclass =~ s/^\s+|\s+$//g;
	$roles =~ s/^\s+|\s+$//g;
	my @roles = split /,/, $roles;

	my $code = "package $class;\n";

	$code .= "\nuse Moose;";
	$code .= $comments
		? " # automatically turns on strict and warnings\n"
		: "\n";
		
	if($namespace_autoclean) {
		$code .= "use namespace::clean;";
		$code .= $comments
			? " # Keep imports out of your namespace\n"
			: "\n";
	}

	if(scalar @{$self->subtypes}) {
		# If there is at least one subtype, we need to add this import
		$code .= "use Moose::Util::TypeConstraints;\n";
	}

	$code .= "\nextends '$superclass';\n" if $superclass ne '';

	$code .= "\n" if scalar @roles;
	for my $role (@roles) {
		$code .= "with '$role';\n";
	}

	$code .= "\n" if scalar @{$self->attributes};
	# Generate attributes
	for my $attribute (@{$self->attributes}) {
		$code .= $attribute->to_code($comments);
	}

	# Generate subtypes
	$code .= "\n" if scalar @{$self->subtypes};
	for my $subtype (@{$self->subtypes}) {
		$code .= $subtype->to_code($comments);
	}

	# Generate methods
	$code .= "\n" if scalar @{$self->methods};
	for my $method (@{$self->methods}) {
		$code .= $method->to_code($comments);
	}

	if($make_immutable) {
		$code .= "\n__PACKAGE__->meta->make_immutable;";
		$code .= $comments
			? " # Makes it faster at the cost of startup time\n"
			: "\n";
	}
	$code .= "\n1;\n\n";

	return $code;
}

__PACKAGE__->meta->make_immutable;

1;
