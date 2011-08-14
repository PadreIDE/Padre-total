#!/usr/bin/env perl

use v5.14;
use Modern::Perl;

our $VERSION = '0.001';

use Data::Printer { caller_info => 1 };

my @list = qw( 1 3 4 87 5 3 3 65 1 3 );
my %indices_for;

while ( my ( $i, $value ) = each @list ) {
    push $indices_for{$value} //= [] => $i;
}

p %indices_for;

1;

__END__
