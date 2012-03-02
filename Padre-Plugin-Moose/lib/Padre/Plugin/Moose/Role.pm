package Padre::Plugin::Moose::Role;

use Moose;
use namespace::clean;

our $VERSION = '0.16';

with 'Padre::Plugin::Moose::Role::CanGenerateCode';
with 'Padre::Plugin::Moose::Role::HasClassMembers';
with 'Padre::Plugin::Moose::Role::CanProvideHelp';
with 'Padre::Plugin::Moose::Role::CanHandleInspector';

has 'name' => ( is => 'rw', isa => 'Str' );
has 'requires_list' => ( is => 'rw', isa => 'Str', default => '' );

sub generate_moose_code {
	my $self             = shift;
	my $code_gen_options = shift;

	my $role     = $self->name;
	my $requires = $self->requires_list;

	$role     =~ s/^\s+|\s+$//g;
	$requires =~ s/^\s+|\s+$//g;
	my @requires = split /,/, $requires;

	my $code = "package $role;\n";
	$code .= "\nuse Moose::Role;\n";

	# If there is at least one subtype, we need to add this import
	if ( scalar @{ $self->subtypes } ) {
		$code .= "use Moose::Util::TypeConstraints;\n";
	}

	$code .= "\n" if scalar @requires;
	for my $require (@requires) {
		$code .= "requires '$require';\n";
	}

	# Generate class members
	$code .= $self->to_class_members_code($code_gen_options);

	$code .= "\n1;\n\n";

	return $code;
}

# Generate Mouse code!
sub generate_mouse_code {
	my $self             = shift;
	my $code_gen_options = shift;

	my $role     = $self->name;
	my $requires = $self->requires_list;

	$role     =~ s/^\s+|\s+$//g;
	$requires =~ s/^\s+|\s+$//g;
	my @requires = split /,/, $requires;

	my $code = "package $role;\n";
	$code .= "\nuse Mouse::Role;\n";

	# If there is at least one subtype, we need to add this import
	if ( scalar @{ $self->subtypes } ) {
		$code .= "use Mouse::Util::TypeConstraints;\n";
	}

	$code .= "\n" if scalar @requires;
	for my $require (@requires) {
		$code .= "requires '$require';\n";
	}

	# Generate class members
	$code .= $self->to_class_members_code($code_gen_options);

	$code .= "\n1;\n\n";

	return $code;
}

sub generate_moosex_declare_code {
	my $self             = shift;
	my $code_gen_options = shift;

	my $role     = $self->name;
	my $requires = $self->requires_list;

	$role     =~ s/^\s+|\s+$//g;
	$requires =~ s/^\s+|\s+$//g;
	my @requires = split /,/, $requires;


	my $role_body = '';

	# If there is at least one subtype, we need to add this import
	if ( scalar @{ $self->subtypes } ) {
		$role_body .= "use Mouse::Util::TypeConstraints;\n";
	}

	$role_body .= "\n" if scalar @requires;
	for my $require (@requires) {
		$role_body .= "requires '$require';\n";
	}

	# Generate class members
	$role_body .= $self->to_class_members_code($code_gen_options);

	my @lines = split /\n/, $role_body;
	for my $line (@lines) {
		$line = "\t$line" if $line ne '';
	}
	$role_body = join "\n", @lines;

	return "use MooseX::Declare;\nrole $role {\n$role_body\n}\n\n";
}

sub provide_help {
	require Wx;
	return Wx::gettext('A role provides some piece of behavior or state that can be shared between classes.');
}

sub read_from_inspector {
	my $self = shift;
	my $grid = shift;

	my $row = 0;
	for my $field (qw(name requires_list)) {
		$self->$field( $grid->GetCellValue( $row++, 1 ) );
	}
}

sub write_to_inspector {
	my $self = shift;
	my $grid = shift;

	my $row = 0;
	for my $field (qw(name requires_list)) {
		$grid->SetCellValue( $row++, 1, $self->$field );
	}
}

sub get_grid_data {
	require Wx;
	return [
		{ name => Wx::gettext('Name:') },
		{ name => Wx::gettext('Requires:') },
	];
}

__PACKAGE__->meta->make_immutable;

1;
