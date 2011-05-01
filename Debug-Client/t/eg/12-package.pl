use strict;
use warnings;

$| = 1;
use t::eg::Test;

my @fib = t::eg::Test::fib(5);

print "@fib\n";
my $x = 42;
print "$x\n";

my @uniq = t::eg::Test::unique(2, 4, 2, 7);

print "@uniq\n";

$x++;
print "$x\n";


