use strict;
use warnings;

$| = 1;

my $x = 1;
my $y = 20;
$x++;
$y = 3;
my $q = f();
$q++;


sub f {
	my $x;
	$x = 42;
	$y++;
	my $z = $x + $y;
	return $z;
}