#!/usr/bin/perl

BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 2;

ok( $] >= 5.008, 'Perl version is new enough' );

use_ok( 'Padre::Plugin::ConfigSync' );
