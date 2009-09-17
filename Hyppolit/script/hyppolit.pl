#!/usr/bin/perl 
use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib";
use Hyppolit;

Hyppolit->run(@ARGV);

