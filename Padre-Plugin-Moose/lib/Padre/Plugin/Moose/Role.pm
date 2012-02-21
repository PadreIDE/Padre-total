package Padre::Plugin::Moose::Role;

use namespace::clean;
use Moose;

has 'name'          => ( is => 'rw', isa => 'Str' );
has 'requires_list' => ( is => 'rw', isa => 'Str' );

sub to_code {
	my $self = shift;

	my $role = $self->name;
	my $requires = $self->requires_list;

	$role =~ s/^\s+|\s+$//g;
	$requires =~ s/^\s+|\s+$//g;
	my @requires = split /,/, $requires;

	# if($role eq '') {
		# $self->main->error(Wx::gettext('Role name cannot be empty'));
		# $self->{role_text}->SetFocus();
		# return;
	# }
	
	# if(scalar @requires == 0) {
		# $self->main->error(Wx::gettext('Requires list cannot be empty'));
		# $self->{requires_text}->SetFocus();
		# return;
	# }

	my $code = "package $role;\n";
	$code .= "\nuse Moose::Role;\n";

	$code .= "\n" if scalar @requires;
	for my $require (@requires) {
		$code .= "requires '$require';\n";
	}
	$code .= "\n1;\n\n";

	return $code;
}

__PACKAGE__->meta->make_immutable;

1;
