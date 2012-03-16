#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 2;
use t::lib::Test;

use_ok('Madre');
use_ok('Madre::DB');
