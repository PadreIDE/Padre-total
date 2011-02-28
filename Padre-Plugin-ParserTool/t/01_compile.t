#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 3;

use_ok( 'Padre::Plugin::ParserTool'         );
use_ok( 'Padre::Plugin::ParserTool::FBP'    );
use_ok( 'Padre::Plugin::ParserTool::Dialog' );
