package Padre::Document::Perl::FunctionList;

use 5.008;
use strict;
use warnings;
use Padre::Task2::FunctionList ();

our $VERSION = '0.62';
our @ISA     = 'Padre::Task2::FunctionList';





######################################################################
# Padre::Task2::FunctionList Methods

sub find {
	my $n = "\\cM?\\cJ";
	return grep { defined $_ } $_[1] =~ m/
		(?:
		(?:$n)*__(?:DATA|END)__\b.*
		|
		$n$n=\w+.*?$n$n=cut\b(?=.*?$n$n)
		|
		(?:^|$n)\s*sub\s+(\w+(?:::\w+)*)
		)
	/sgx;
}

1;
