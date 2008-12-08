use strict;
use warnings;

$| = 1;

sub fib {
    my ($n) = @_;

    die if not defined $n or $n !~ /^\d+$/;
    return 0 if $n == 0;
    return 1 if $n == 1 or $n == 2;
    my $val = fibx($n-1) + fib($n-2);

    return $val;
}
sub fibx {
    my $n = shift;
    my $val = fib($n);
    return $val;
}

my $res = fib(10);
print "$res\n";
