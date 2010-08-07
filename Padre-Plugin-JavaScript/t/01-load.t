#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;

	# Twice to avoid a warning
	$DB::single = $DB::single = 1;
}

use Test::NeedsDisplay;
use Test::More tests => 5;
use Test::NoWarnings;
use Class::Autouse ':devel';

ok( $] >= 5.008, 'Perl version is new enough' );

use_ok( 'Wx'                             );
diag( "Tests find Wx: $Wx::VERSION " . Wx::wxVERSION_STRING() );
use_ok( 'Padre::Plugin::JavaScript'      );
use_ok( 'Padre::Document::JavaScript'      );

