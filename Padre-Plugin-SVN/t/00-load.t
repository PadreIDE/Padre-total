#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More;

# BEGIN {
	# if ( not $ENV{DISPLAY} and not $^O eq 'MSWin32' ) {
		# plan skip_all => 'Needs DISPLAY';
		# exit 0;
	# }
# }

plan tests => 3;

use_ok('Padre::Plugin::SVN::Wx::BlameTree');
use_ok('Padre::Plugin::SVN::Wx::SVNDialog');
use_ok('Padre::Plugin::SVN');
