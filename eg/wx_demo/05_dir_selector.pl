#!/usr/bin/perl

use 5.008;
use strict;
use warnings;

use lib 'lib';
use Padre::Demo;


my $empty = dir_selector();
message(text => $empty);

