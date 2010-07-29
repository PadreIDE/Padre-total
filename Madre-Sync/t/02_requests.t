#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}
use Test::More tests => 7;

use_ok( 'Catalyst::Test', 'Madre::Sync' );
use_ok( 'Madre::Sync::Controller::Root' );
use_ok( 'Madre::Sync::Controller::User' );
use_ok( 'Madre::Sync::Controller::Conf' );

ok( request('/')->is_success,       'Request should succeed' );
ok( request('/user')->is_success,   'Request should succeed' );
ok( request('/config')->is_success, 'Request should succeed' );
