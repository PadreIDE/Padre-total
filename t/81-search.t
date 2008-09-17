#!/usr/bin/perl

use strict;
use warnings;


use Test::More;
use t::lib::Padre;
use Padre::Util 'get_matches';

my $tests;
plan tests => $tests;

SCOPE: {
    my ($start, $end, @matches) = get_matches("abc", qr/x/, 0, 0);
    is_deeply(\@matches, [], 'no match');
    BEGIN { $tests += 1; }
}

SCOPE: {
    my (@matches) = get_matches("abc", qr/b/, 0, 0);
    is_deeply(\@matches, [ 1, 2, [1,2] ], 'one match');
    BEGIN { $tests += 1; }
}

