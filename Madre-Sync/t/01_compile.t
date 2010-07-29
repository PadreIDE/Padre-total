#!/usr/bin/perl

use 5.008;
use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}
use Test::More tests => 7;

use_ok( 'Madre::Sync'                   );
use_ok( 'Madre::Sync::Schema'           );
use_ok( 'Madre::Sync::View::TT'         );
use_ok( 'Madre::Sync::Model::padreDB'   );
use_ok( 'Madre::Sync::Controller::Root' );
use_ok( 'Madre::Sync::Controller::User' );
use_ok( 'Madre::Sync::Controller::Conf' );
