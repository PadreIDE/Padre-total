#!/usr/bin/perl

use 5.008;
use strict;
use warnings;

use lib 'lib';
use Wx::Perl::Dialog::Simple;

my $how = entry(title => "Asking Foo", prompt => "How are you today?");
message(text => $how);
