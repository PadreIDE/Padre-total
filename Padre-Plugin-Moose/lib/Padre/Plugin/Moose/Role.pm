package Padre::Plugin::Moose::Role;

use namespace::clean;
use Moose;

our $VERSION = '0.08';

with 'Padre::Plugin::Moose::Role::CanGenerateCode';
with 'Padre::Plugin::Moose::Role::HasClassMembers';
with 'Padre::Plugin::Moose::Role::CanProvideHelp';
with 'Padre::Plugin::Moose::Role::CanHandleInspector';

has 'name' => ( is => 'rw', isa => 'Str' );
has 'requires_list' => ( is => 'rw', isa => 'Str', default => '' );

sub generate_code {
	my $self     = shift;
	my $comments = shift;

	my $role     = $self->name;
	my $requires = $self->requires_list;

	$role     =~ s/^\s+|\s+$//g;
	$requires =~ s/^\s+|\s+$//g;
	my @requires = split /,/, $requires;

	my $code = "package $role;\n";
	$code .= "\nuse Moose::Role;\n";

	# If there is at least one subtype, we need to add this import
	$code .= "use Moose::Util::TypeConstraints;\n"
		if scalar @{ $self->subtypes };

	$code .= "\n" if scalar @requires;
	for my $require (@requires) {
		$code .= "requires '$require';\n";
	}

	# Generate class members
	$code .= $self->to_class_members_code($comments);

	$code .= "\n1;\n\n";

	return $code;
}

sub provide_help {
	require Wx;
	return Wx::gettext('A role provides some piece of behavior or state that can be shared between classes.');
}

__PACKAGE__->meta->make_immutable;

1;
