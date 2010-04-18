package Padre::Task2::Addition;

use 5.008005;
use strict;
use warnings;
use Padre::Task2 ();

our $VERSION = '0.59';
our @ISA     = 'Padre::Task2';

sub run {
	my $self = shift;
	$self->{z} = $self->{x} + $self->{y};
	return 1;
}

1;
