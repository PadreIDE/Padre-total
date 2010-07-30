#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 8;
use HTTP::Request::Common qw{ GET POST };

use_ok( 'Catalyst::Test', 'Madre::Sync' );

ok( request('/')->code == 404,            'request /            404' );
ok( request(GET '/')->code == 404,        'GET     /            404' );
ok( request('/bad')->code == 404,         'request /bad         404' );
ok( request('/login')->is_success,        'request /login       200' );
ok( request(GET '/login')->is_success,    'GET     /login       200' );
ok( request('/user')->code == 415,        'request /user        415 -> /login' );
ok( request('/user/config')->code == 415, 'request /user/config 415 -> /login' );
