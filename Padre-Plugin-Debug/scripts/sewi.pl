#!/usr/bin/env perl

use 5.010;
use strict;
use warnings;

use diagnostics;
use utf8;
use Data::Printer { caller_info => 1 };

use FindBin qw($Bin);
use lib ("$Bin");

use ExSewi qw(wh);

#bp 17, this is 16
wh("foo");

1;
