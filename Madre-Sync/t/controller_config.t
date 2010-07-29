#!/usr/bin/env perl

use strict;
use warnings;
use Test::More tests => 3;

use_ok( 'Catalyst::Test', 'Madre::Sync' );
use_ok( 'Madre::Sync::Controller::config' );

ok( request('/config')->is_success, 'Request should succeed' );
