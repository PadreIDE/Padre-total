#!/usr/bin/env perl
use strict;
use warnings;

# Turn on $OUTPUT_AUTOFLUSH
$| = 1;

# Don't run tests during end-user installs
use Test::More;
plan( skip_all => 'Author tests not required for installation' )
	unless ( $ENV{RELEASE_TESTING} or $ENV{AUTOMATED_TESTING} );
	
eval { 
	require Test::Kwalitee; 
	Test::Kwalitee->import() 
	};

plan( skip_all => 'Test::Kwalitee not installed; skipping' ) if $@;

1;

__END__
