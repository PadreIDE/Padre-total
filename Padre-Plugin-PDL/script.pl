#!/usr/bin/perl

use 5.010;
use strict;
use warnings;

require Capture::Tiny;
my $help_list_output = Capture::Tiny::capture_stdout(
    sub {
        require PDL::Doc::Perldl;
        PDL::Doc::Perldl::apropos('.*');
        return;
    }
);

my %help = ();
for my $line ( split /\n/, $help_list_output ) {
    state $topic;
    if ( $line =~ /^(\S+)\s+(.+)$/ ) {
        $topic = $1;
        $help{$topic} = $2;
    }
    else {
        if ( defined $topic ) {
            $line =~ s/^\s+//;
            $help{$topic} .= " $line";
        }
    }
}

open my $fh, '>', 'stdout.txt' or die "Cannot open stdout.txt\n";
use Data::Printer;
print $fh p(%help);
close $fh;
