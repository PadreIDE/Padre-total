#!/usr/bin/perl

use 5.006;
use strict;
use warnings;
use Test::More;

plan( tests => 4 );

# Search for Padre version
use_ok('Padre');
ok( $Padre::VERSION, 'Check Padre module version' );

my $ext_vers = `$^X script/padre --version`;
like( $ext_vers, qr/Perl Application Development and Refactoring Environment/, 'Version string text' );
like( $ext_vers, qr/$Padre::VERSION/, 'Version number' );
