#!/usr/bin/perl

#use 5.008;
use strict;

# taken straight from the Padre test
# 01-load.t

use Test::More;

BEGIN {
	if ( not $ENV{DISPLAY} and not $^O eq 'MSWin32' ) {
		plan skip_all => 'Needs DISPLAY';
		exit 0;
	}
}

plan tests => 1;

use_ok('Padre::Plugin::HTML');

diag("Testing Padre::Plugin::HTML $Padre::Plugin::HTML::VERSION, Perl $], $^X");
