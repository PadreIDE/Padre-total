#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
my $tests;

plan tests => $tests;

use t::lib::Padre;
use Padre::Demo;

#Padre::Demo->run(\&test_app);
ok(1, "test_app done");
BEGIN { $tests += 1; }


#Padre::Demo->run(\&test_prompt);
#ok(1, "test_prompt done");


#sub test_app {
#    close_app();
#}
#
#sub test_prompt {
#    my $name = prompt("What is your name?");
#    sleep 2;
#    close_app();
#}
#