#!perl
use strict;
use warnings;

use lib 'lib';
use Padre::Demo;
Padre::Demo->run(\&main);

sub main {
   my ($frame, $output) = @_;

   my $name = $frame->prompt("What is your name?\n");
   $output->AddText("How are you $name today?\n");

   return;
}

