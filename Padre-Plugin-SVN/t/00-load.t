#!/usr/bin/perl

use 5.008;
use strict;


use Test::More;

# taken straight from the Padre test 
# 01-load.t

BEGIN {
	unless ( $ENV{DISPLAY} or $^O eq 'MSWin32' ) {
		plan skip_all => 'Needs DISPLAY';
		exit 0;
	}
}

plan( tests => 1 );
	
use_ok( 'Padre::Plugin::SVN' );

diag( "Testing Padre::Plugin::SVN $Padre::Plugin::SVN::VERSION, Perl $], $^X" );
