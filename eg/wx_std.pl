#!perl
use strict;
use warnings;

use lib 'lib';
use Padre::Demo;
Padre::Demo->run(\&main);

sub main {
   my $name = prompt("What is your name?\n");
   print_out("How are you $name today?\n");

   my $filename = promp_input_file("Select source file");
   print_out("The file you selected is $filename\n");

   return;
}

