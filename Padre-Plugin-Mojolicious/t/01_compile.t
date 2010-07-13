#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 4;
use Test::NoWarnings;

use_ok( 'Padre::Plugin::Mojolicious'         );
use_ok( 'Padre::Plugin::Mojolicious::Util'   );
use_ok( 'Padre::Plugin::Mojolicious::NewApp' );
