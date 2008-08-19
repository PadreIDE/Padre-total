#!/usr/bin/perl
use strict;
use warnings;

#use Time::HiRes;
use Test::More;
my $tests;

plan tests => $tests;

use Padre::Demo;

Padre::Demo->run(\&test_app);

sub test_app {
#    sleep 1;
    close_app();
}

    #my $name = prompt("What is your name?");

{
    ok(1, "Dummy test");
    BEGIN { $tests += 1; }
}

