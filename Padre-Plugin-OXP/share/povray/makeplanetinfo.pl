#!/usr/bin/perl
use strict;
use warnings;

use Text::CSV;
use Data::Dumper;

my $galaxy_csv = shift @ARGV;
my ($galaxy_num) = $galaxy_csv =~ /(\d)/;
my $galaxy_index = $galaxy_num - 1;

my $csv = Text::CSV->new;
open( my $fh , $galaxy_csv ) or die $!;
my $headings = $csv->getline($fh);
#die Dumper $headings;

while ( my $row = $csv->getline($fh) ) {
        my %info;
        @info{@$headings} = @$row;
        #warn Dumper \%info;
        my $planet = $info{'Planet #'};
        my $name = $info{Name};
        print qq|
        "$galaxy_index $planet" = {
                texture = "gal-$galaxy_num-$name.png";
        };
       |
        
}