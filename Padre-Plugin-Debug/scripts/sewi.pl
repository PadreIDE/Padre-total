#!/usr/bin/env perl

use 5.010;
use strict;
use warnings;
# Turn on $OUTPUT_AUTOFLUSH
$| = 1;
use diagnostics;
use utf8;

use Data::Printer { caller_info => 1 };
use FindBin qw($Bin);
use lib ("$Bin");

use ExSewi qw(wh eh);

my $fred = 'bloggs one';

#bp 20, this is 19
wh("foo");

eh($fred);
say $fred;

say 'END';

1;
