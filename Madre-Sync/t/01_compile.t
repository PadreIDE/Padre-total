#!/usr/bin/env perl

use 5.008;
use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}
use Test::More tests => 1;

use_ok( 'Madre::Sync' );
