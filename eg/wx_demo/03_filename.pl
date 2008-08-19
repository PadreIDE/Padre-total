#!/usr/bin/perl

use 5.008;
use strict;
use warnings;

use lib 'lib';
use Padre::Demo;
Padre::Demo->run(\&main);

sub main {
   my $filename = promp_input_file("Select source file");
   print_out("The file you selected is $filename\n");

   return;
}




