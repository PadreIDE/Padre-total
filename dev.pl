#!/usr/bin/perl

use 5.008;
use strict;
use warnings;

# This script is only used to run the application from
# its development location
# No need to distribute it

use FindBin;
use Probe::Perl;
$ENV{PADRE_DEV} = 1;
$ENV{PADRE_HOME} = $FindBin::Bin;
my $perl = Probe::Perl->find_perl_interpreter;
system qq["$perl" -I$FindBin::Bin/lib -I$FindBin::Bin/../plugins/par/lib $FindBin::Bin/script/padre @ARGV]; 
