package Padre::Plugin::Parrot::HL;
use strict;
use warnings;

sub colorize {
	my ($self, @args) = @_;
	my ($pbc, $path) = $self->pbc_path;
	
	print "PP::HL: $self  $pbc  $path\n";

	return;
}

1;
