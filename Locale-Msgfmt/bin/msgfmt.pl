#!/usr/bin/perl -I lib

use Locale::Msgfmt;
use Getopt::Long;

use strict;
use warnings;

my($opt_o, $opt_f);
GetOptions("output-file|o=s" => \$opt_o, "use-fuzzy|f" => \$opt_f);
my $in = shift;
if(!(defined($in) && defined($opt_o))) {
  print "usage: $0 [-f] -o output.mo input.po\n";
  exit(1);
}

msgfmt({in => $in, out => $opt_o, fuzzy => $opt_f});
