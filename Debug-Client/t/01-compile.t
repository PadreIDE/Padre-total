#!/usr/bin/perl

use strict;
use Test::More tests => 17;

use_ok('Debug::Client');
use_ok('t::lib::Debugger');

use_ok('Carp',                 '1.20');
use_ok('IO::Socket::IP',       '0.2');
use_ok('PadWalker',            '1.96');
use_ok('Term::ReadLine',       '1.04');
use_ok('Term::ReadLine::Perl', '1.0303');
use_ok('constant',             '1.21');

use_ok('Exporter ',     '5.64');
use_ok('File::HomeDir', '1');
use_ok('File::Spec',    '3.4');
use_ok('File::Temp',    '0.2301');
use_ok('Test::Class',   '0.39');
use_ok('Test::Deep',    '0.11');
use_ok('Test::More',    '0.98');
use_ok('parent',        '0.225');
use_ok('version',       '0.88');

diag("Info: Testing Debug::Client $Debug::Client::VERSION");
diag("Info: Perl $^V");

done_testing();

__END__
