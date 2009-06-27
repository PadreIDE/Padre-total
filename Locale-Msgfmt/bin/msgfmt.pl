#!/usr/bin/perl

use Locale::Msgfmt;
use Getopt::Long;

use strict;
use warnings;

my($opt_o, $opt_f);
GetOptions("output-file|o=s" => \$opt_o, "use-fuzzy|f" => \$opt_f);
my $in = shift;

msgfmt({in => $in, out => $opt_o, fuzzy => $opt_f});
