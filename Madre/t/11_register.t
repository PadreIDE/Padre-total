#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 2;
use t::lib::Test;

# The order is important
use Madre;
use Dancer::Test;

route_exists(
	[ GET => '/register'],
	'a route handler is defined for /register',
);

response_status_is(
	[ GET => '/register' ],
	200,
	'response status is 200 for /',
);
