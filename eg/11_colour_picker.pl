#!/usr/bin/perl

use 5.008;
use strict;
use warnings;

use lib 'lib';
use Wx::Perl::Dialog::Simple;

my $empty = colour_picker() || '';
my $str = sprintf("%x%x%x",  @$empty);
print "$str\n";
message(text => $str);

