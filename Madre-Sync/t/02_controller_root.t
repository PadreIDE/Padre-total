#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}
use Test::More tests => 2;

use_ok( 'Catalyst::Test', 'Madre::Sync' );

ok( request('/')->is_success, 'Request should succeed' );
