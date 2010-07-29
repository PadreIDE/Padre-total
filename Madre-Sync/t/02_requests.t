#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}
use Test::More tests => 9;

use_ok( 'Catalyst::Test', 'Madre::Sync' );
use_ok( 'Madre::Sync::Controller::Root' );
use_ok( 'Madre::Sync::Controller::User' );
use_ok( 'Madre::Sync::Controller::Conf' );

ok( request('/')->is_success,             'Request should succeed' );
ok( request('/bad')->code == 404,         'Request should fail with 404' );
ok( request('/login')->is_success,        'Request should succeed' );
ok( request('/user')->code == 415,        'Request should bounce to login page with 415' );
ok( request('/user/config')->code == 415, 'Request should bounce to login page with 415' );
