#!/usr/bin/perl

use 5.008;
use strict;
use warnings;

# This script is only used to run the application from
# its development location
# No need to distribute it

use FindBin;
use Probe::Perl;
$ENV{PADRE_DEV}  = 1;
$ENV{PADRE_HOME} = $FindBin::Bin;
my $perl = Probe::Perl->find_perl_interpreter;
my @cmd  = (
        qq[$perl],
        qq[-I$FindBin::Bin/lib],
        qq[-I$FindBin::Bin/../plugins/par/lib],
);
if ( grep { $_ eq '-d' } @ARGV ) {
        @ARGV = grep { $_ ne '-d' } @ARGV;
        push @cmd, '-d';
}
push @cmd, qq[$FindBin::Bin/script/padre], @ARGV;
print join( ' ', @cmd ) . "\n";
system( @cmd );

#my $cmd  = qq["$perl" -I$FindBin::Bin/lib -I$FindBin::Bin/../plugins/par/lib $FindBin::Bin/script/padre @ARGV];
#print $cmd . "\n";
#system $cmd;

