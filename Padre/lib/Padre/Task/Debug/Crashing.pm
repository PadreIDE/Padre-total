package Padre::Task::Debug::Crashing;

use 5.008;
use strict;
use warnings;
use Padre::Task ();

our $VERSION = '0.59';
our @ISA     = 'Padre::Task';

sub run {
	my ($self) = @_;

	sleep 5;
	die "This is a debugging task that simply crashes after running for 5 seconds!";

	# Commented out temporarily to appease xt/critic.t
	# return 1;
}

sub finish {
	my $self = shift;
	warn "This should never be reached since the task crashed during run()!";
}

1;

# Copyright 2008-2010 The Padre development team as listed in Padre.pm.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.
