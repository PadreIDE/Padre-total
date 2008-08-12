#!perl
use strict;
use warnings;

use lib 'lib';
use Padre::Demo;
Padre::Demo->run(\&main);

sub main {
   my ($app, $output) = @_;

   my $name = $app->prompt("What is your name?\n");
   $output->AddText("How are you $name today?\n");

   my $filename = $app->promp_input_file("Select source file");
   $output->AddText("The file you selected is $filename\n");
 
   return;
}

