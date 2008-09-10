#!/usr/bin/perl

use 5.008;
use strict;
use warnings;

use lib 'lib';
use Wx::Perl::Dialog;

print map {"$_\n"} single_choice( choices => [qw(a b c)] );
