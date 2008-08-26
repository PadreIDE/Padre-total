#!/usr/bin/perl

use 5.008;
use strict;
use warnings;

use lib 'lib';
use Padre::Demo;

print map {"$_\n"} choice( choices => [qw(a b c)] );
