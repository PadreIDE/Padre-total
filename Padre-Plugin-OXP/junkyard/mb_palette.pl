#!/usr/bin/perl
use strict;
use warnings;
use Data::Dumper;
use File::Basename;
my $file = shift @ARGV;
my $max = shift @ARGV;
$max ||= 255;
my $begin = shift @ARGV;
$begin = defined $begin ? $begin : 0;

open( my $fh , '<', $file ) or die $!;
my $named = basename($file);



my @p;

while (my $l = <$fh> ) {
    chomp $l;
    my ($palette) = $l =~ /^palette (.*);/;
    if ($palette) {
        @p = split /\s+/ , $palette;
    }
} 

die "No palette found" unless @p;

if (scalar @p > $max) {
   warn "Truncating " . scalar @p . " to $max entries, starting at $begin ";
   @p =splice @p,$begin,$begin+$max;
}

my $incr = 1 / scalar @p;

my $pos = 0;
printf "#declare CM_${named}_${begin}_${max} = color_map {\n";
foreach my $p (@p) {
    my @parts = $p =~ /(\w{2})(\w{2})(\w{2})/;
    my @rgb = map { hex($_) / 255  } @parts;
#    print Dumper \@rgb;
  
    printf "[%f rgb <%f,%f,%f>]\n" , $pos, @rgb;
   
} continue {
    $pos += $incr;
}
printf "}\n\n";


