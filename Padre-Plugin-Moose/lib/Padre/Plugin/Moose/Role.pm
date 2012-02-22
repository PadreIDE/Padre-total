package Padre::Plugin::Moose::Role;

use namespace::clean;
use Moose;

our $VERSION = '0.05';

with 'Padre::Plugin::Moose::CodeGen';

has 'name' => ( is => 'rw', isa => 'Str' );
has 'requires_list' => ( is => 'rw', isa => 'Str', default => '' );

with 'Padre::Plugin::Moose::CodeGen';

sub to_code {
	my $self = shift;

	my $role     = $self->name;
	my $requires = $self->requires_list;

	$role     =~ s/^\s+|\s+$//g;
	$requires =~ s/^\s+|\s+$//g;
	my @requires = split /,/, $requires;

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
