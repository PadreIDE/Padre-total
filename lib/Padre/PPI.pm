package Padre::PPI;

use 5.008;
use strict;
use warnings;
use PPI;

our $VERSION = '0.20';





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

# This does not guarantee a match: the location of
# a token is only the first character
# TODO: PPIx::IndexOffsets or something similar might help.
# TODO: See the 71... tests. If we don#t flush locations there, this breaks.
sub find_token_at_location {
	my $document = shift;
	my $location = shift;
	
	if (not defined $document
	    or not $document->isa('PPI::Document')
	    or not defined $location
	    or not ref($location) eq 'ARRAY') {
		require Carp;
		Carp::croak("find_token_at_location() requires a PPI::Document and a PPI-style location is arguments");
	}

	$document->index_locations();

	my $variable_token = $document->find_first(
		sub {
			my $elem = $_[1];
			return 0 if not $elem->isa('PPI::Token');
			my $loc = $elem->location;
			return 0 if $loc->[0] != $location->[0] or $loc->[1] != $location->[1];
			return 1;
		},
	);

	return $variable_token;
}

# given either a PPI::Token::Symbol (i.e. a variable)
# or a PPI::Token which contains something that looks like
# a variable (quoted vars, interpolated vars in regexes...)
# find where that variable has been declared lexically.
# Doesn't find stuff like "use vars...".
sub find_variable_declaration {
	my $cursor   = shift;
	return()
	  if not $cursor or not $cursor->isa("PPI::Token");
	my ($varname, $token_str);
	if ($cursor->isa("PPI::Token::Symbol")) {
		$varname = $cursor->canonical;
		$token_str = $cursor->content;
	}
	else {
		my $content = $cursor->content;
		if ($content =~ /([\$@%*][\w:']+)/) {
			$varname = $1;
			$token_str = $1;
		}
	}
	return()
	  if not defined $varname;

	my $document = $cursor->top();
	my $declaration;
	while ( $cursor = $cursor->parent ) {
		last if $cursor == $document;
		if ($cursor->isa("PPI::Structure::Block")) {
			my @elems = $cursor->elements;
			foreach my $elem (@elems) {
				if ($elem->isa("PPI::Statement::Variable")
				    and grep {$_ eq $varname} $elem->variables) {
					$declaration = $elem;
					last;
				}
			}
			last if $declaration;
		}
	} # end while not top level

	return $declaration;
}


1;

# Copyright 2008 Gabor Szabo.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.
