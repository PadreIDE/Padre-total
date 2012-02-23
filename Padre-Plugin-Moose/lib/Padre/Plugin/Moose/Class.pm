package Padre::Plugin::Moose::Class;

use Moose;
use namespace::clean;

our $VERSION = '0.08';

with 'Padre::Plugin::Moose::CanGenerateCode';
with 'Padre::Plugin::Moose::HasClassMembers';
with 'Padre::Plugin::Moose::CanProvideHelp';

has 'name'         => ( is => 'rw', isa => 'Str',      default => '' );
has 'superclasses' => ( is => 'rw', isa => 'Str',      default => '' );
has 'roles'        => ( is => 'rw', isa => 'Str',      default => '' );
has 'immutable'           => ( is => 'rw', isa => 'Bool' );
has 'namespace_autoclean' => ( is => 'rw', isa => 'Bool' );

sub generate_code {
	my $self     = shift;
	my $comments = shift;

	my $class               = $self->name;
	my $superclasses        = $self->superclasses;
	my $roles               = $self->roles;
	my $namespace_autoclean = $self->namespace_autoclean;
	my $make_immutable      = $self->immutable;

	$class        =~ s/^\s+|\s+$//g;
	$superclasses =~ s/^\s+|\s+$//g;
	$roles        =~ s/^\s+|\s+$//g;
	my @roles = split /,/, $roles;

	my $code = "package $class;\n";

	$code .= "\nuse Moose;";
	$code .=
		$comments
		? " # automatically turns on strict and warnings\n"
		: "\n";

	if ($namespace_autoclean) {
		$code .= "use namespace::clean;";
		$code .=
			$comments
			? " # Keep imports out of your namespace\n"
			: "\n";
	}

	# If there is at least one subtype, we need to add this import
	$code .= "use Moose::Util::TypeConstraints;\n"
		if scalar @{ $self->subtypes };

	$code .= "\nextends '$superclasses';\n" if $superclasses ne '';

	$code .= "\n" if scalar @roles;
	for my $role (@roles) {
		$code .= "with '$role';\n";
	}

	# Generate class members
	$code .= $self->to_class_members_code($comments);

	if ($make_immutable) {
		$code .= "\n__PACKAGE__->meta->make_immutable;";
		$code .=
			$comments
			? " # Makes it faster at the cost of startup time\n"
			: "\n";
	}
	$code .= "\n1;\n\n";

	return $code;
}

sub provide_help {
	require Wx;
	return Wx::gettext(' A class is a blueprint of how to create objects of itself. A class can contain attributes, subtypes and methods which enable objects to have state and behavior.');
}

__PACKAGE__->meta->make_immutable;

1;
