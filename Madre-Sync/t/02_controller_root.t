#!/usr/bin/env perl

use strict;
use warnings;
use Test::More tests => 2;

use_ok( 'Catalyst::Test', 'Madre::Sync' );

ok( request('/')->is_success, 'Request should succeed' );
