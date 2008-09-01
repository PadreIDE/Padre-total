#!/usr/bin/perl

use 5.008;
use strict;
use warnings;

use lib 'lib';
use Wx::Perl::Dialog;


my $empty = password();
message(text => $empty);

#my $name = entry(title => "What is your name?");
#display_text("How are you $name today?\n");

#my $how = entry(title => $name, prompt => "How are you?");
#display_text("$name,  $how");
