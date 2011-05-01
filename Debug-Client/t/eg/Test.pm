package t::eg::Test;
use strict;
use warnings;

$main::from_test = 42;

sub fib {
	my $n = shift;
	return 1 if $n == 1;
	return (1,1) if $n == 2;
	
	my $counter;
	
	my @fib = (1, 1);
	for (3..$n) {
		$counter++;
		push @fib, $fib[-1] + $fib[-2];
		
	}
	return @fib;
}

sub unique {
	my %seen;
	my @values;
	foreach my $v (@_) {
		if (not $seen{$v}) {
			push @values, $v;
			$seen{$v} = 1;
		}
	}

	return @values;
}

1;
