#!/usr/bin/perl

use 5.008;
use strict;
use warnings;

use lib 'lib';
use Padre::Demo;

my $filename = file_selector();
display_text("The file you selected is $filename\n");

my $file = file_selector(title => "Select source file");
display_text("The file you selected is $file\n");
