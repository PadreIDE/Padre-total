#!/usr/bin/perl
use strict;
use warnings;


use Test::More;
my $tests;

plan tests => $tests;


{
    ok(1, "Dummy test");
    BEGIN { $tests += 1; }
}

