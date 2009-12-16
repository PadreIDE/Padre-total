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


sub fiball {
    my ($n) = @_;
    return 1     if $n == 1;
    return (1,1) if $n == 2;
    my @fib = (1, 1);
    for (3..$n) {
        push @fib, $fib[-1]+$fib[-2];
    }
    return @fib;
}

fiball(3);
my $f4 = fiball(4);
my @f5 = fiball(5);

print "$f4; @f5\n";

