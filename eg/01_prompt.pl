#!/usr/bin/perl

use 5.008;
use strict;
use warnings;

use lib 'lib';
use Wx::Perl::Dialog;


my $empty = entry();
message(text => $empty);

my $name = entry(title => "What is your name?");
message(text => "How are you $name today?\n");

my $how = entry(title => $name, prompt => "How are you?");
message(text => "$name,  $how");
