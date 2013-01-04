#!/usr/bin/perl

use strict;
use Test::More tests => 13;

use_ok('Debug::Client');
use_ok('t::lib::Debugger');

use_ok( 'Carp',                 '1.26' );
use_ok( 'IO::Socket::IP',       '0.18' );
use_ok( 'PadWalker',            '1.96' );
use_ok( 'Term::ReadLine',       '1.07' );
use_ok( 'Term::ReadLine::Perl', '1.0303' );

use_ok( 'File::HomeDir', '0.98' );
use_ok( 'File::Spec',    '3.33' );
use_ok( 'File::Temp',    '0.22' );
use_ok( 'Test::Deep',    '0.110' );
use_ok( 'Test::More',    '0.98' );
use_ok( 'Time::HiRes',   '1.9725' );

diag("Info: Testing Debug::Client $Debug::Client::VERSION");
diag("Info: Perl $^V");

done_testing();

__END__
