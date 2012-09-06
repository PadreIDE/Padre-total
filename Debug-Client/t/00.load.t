#!/usr/bin/perl

use strict;
use Test::More tests => 10;

use_ok('Debug::Client');
use_ok('t::lib::Debugger');

# Check dependencies that are not checked but Client.pm itself
use_ok( 'PadWalker',            '1.92' );
use_ok( 'Term::ReadLine',       '1.07' );
use_ok( 'Term::ReadLine::Perl', '1.0303' );

use_ok( 'Test::More',    '0.98' );
use_ok( 'Test::Deep',    '0.108' );
use_ok( 'File::HomeDir', '0.98' );
use_ok( 'File::Temp',    '0.22' );
use_ok( 'File::Spec',    '3.33' );

diag("Info: Testing Debug::Client $Debug::Client::VERSION");
diag("Info: Perl $^V");
