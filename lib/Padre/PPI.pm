package Padre::PPI;

use 5.008;
use strict;
use warnings;
use PPI;

our $VERSION = '0.11';





#####################################################################
# Assorted Search Functions

sub find_unmatched_brace {
	$_[1]->isa('PPI::Statement::UnmatchedBrace') and return 1;
	$_[1]->isa('PPI::Structure')                 or return '';
	$_[1]->start and $_[1]->finish              and return '';
	return 1;
}





#####################################################################
# Stuff that should be in PPI itself

sub element_depth {
	my $cursor = shift;
	my $depth  = 0;
	while ( $cursor = $cursor->parent ) {
		$depth += 1;
	}
	return $depth;
}

1;
