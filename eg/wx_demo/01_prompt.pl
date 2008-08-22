#!/usr/bin/perl

use 5.008;
use strict;
use warnings;

use lib 'lib';
use Padre::Demo;
Padre::Demo->run(\&main);

sub main {
   #my $out = open_frame();
   my $name = prompt("What is your name?\n");
   print "$name\n";
   print_out("How are you $name today?\n");
   #sleep 2;
   #close_app;
   return;
}

