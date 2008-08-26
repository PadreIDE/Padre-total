#!/usr/bin/perl

use 5.008;
use strict;
use warnings;

use lib 'lib';
use Padre::Demo;

my $name = prompt("What is your name?\n");
#print "$name\n";
display_text("How are you $name today?\n");

