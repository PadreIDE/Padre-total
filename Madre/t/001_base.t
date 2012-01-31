#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 3;

use_ok 'Madre';
use_ok 'Madre::DB';
use_ok 'Madre::Dance::Sync';
