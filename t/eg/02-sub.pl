use strict;
use warnings;

$| = 1;

my $x = 1;
my $y = 2;
my $q = f($x, $y);
my $z = $x + $y;


sub f {
   my ($q, $w) = @_;
   my $multi = $q * $w;
   my $add   = $q + $w;
   return $multi;
}
