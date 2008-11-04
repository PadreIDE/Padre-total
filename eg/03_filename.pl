#!/usr/bin/perl

use 5.008;
use strict;
use warnings;

use lib 'lib';
use Wx::Perl::Dialog::Simple;

my $filename = file_selector();
message(text => "The file you selected is $filename\n");

my $file = file_selector(title => "Select source file");
message(text => "The file you selected is $file\n");
