#!/usr/bin/env perl

use strict;
use warnings;
use Test::More tests => 3;

use_ok( 'Catalyst::Test', 'Madre::Sync' );
use_ok( 'Madre::Sync::Controller::user' );

ok( request('/user')->is_success, 'Request should succeed' );
