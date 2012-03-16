#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 6;
use t::lib::Test;

# The order is important
use Madre;
use Dancer::Test;

# Check all public routes
my @ROUTES = qw{
	/
	/version
	/register
};

foreach ( @ROUTES ) {
	route_exists [ GET => $_ ], "a route handler is defined for $_";
	response_status_is [ 'GET' => $_ ], 200, "response status is 200 for $_";
}
