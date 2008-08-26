#!/usr/bin/perl

use 5.008;
use strict;
use warnings;

use lib 'lib';
use Padre::Demo;

my $filename = promp_input_file("Select source file");
display_text("The file you selected is $filename\n");

