#!/usr/bin/perl
use strict;
use warnings;

use autodie;
use Text::CSV_XS;
use File::Basename qw(dirname);

my $csv = Text::CSV_XS->new;
open my $fh, '<', dirname($0) . '/answers.csv';
my $total = 0;
my %data;
<$fh>;
while (my $line = <$fh>) {
		die if not $csv->parse($line);
		my ($name, $value) = $csv->fields;
		$total += $value;
		$data{$name} = $value;
}

foreach my $name (sort {$data{$b} <=> $data{$a}} keys %data) {
	#print "$name\n";
	my $perc = int (($data{$name}*100+$total*0.5)/$total);
	print "<tr><td>$name</td><td>$data{$name}</td><td>$perc%</td></tr>\n";
}