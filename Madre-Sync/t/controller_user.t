#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}
use Test::More tests => 3;

use_ok( 'Catalyst::Test', 'Madre::Sync' );
use_ok( 'Madre::Sync::Controller::User' );

ok( request('/user')->is_success, 'Request should succeed' );
