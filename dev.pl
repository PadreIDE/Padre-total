#!/usr/bin/perl 
use strict;
use warnings;

# This script is only used to run the application from
# its development location
# No need to distribute it

use FindBin;
$ENV{PADRE_DEV} = 1;
$ENV{PADRE_HOME} = $FindBin::Bin;
system "$^X -Ilib -I../plugins/par/lib bin/padre @ARGV"; 
