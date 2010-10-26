#!/usr/bin/perl
use 5.010;
use strict;
use warnings;
use File::Slurp;

my $html = read_file('properties.html');

  use Web::Scraper;
  my $scraper = scraper {
      process "tr", "properties[]" => scraper {
          process "//td[1]/a/span", "names[]" => 'TEXT'; #array
          process "//td[2]", comment => 'TEXT';
      };
  };
  my $res = $scraper->scrape(\$html);

open my $out,'>','out.yml';
foreach my $e (@{ $res->{properties} }) {
  next unless keys %$e;
  my @names=@{$e->{names}};
  my $c=$e->{comment};
  $c=~s/\Q || / /g;
  $c=~s/\Q{1,4}/(REPLACE_four)/g;
  foreach my $name (@names) {
    if ($name=~/^'([^']+)'$/) {
      $name=$1;
      say $out "  $name: $c";
    } else {
      die "Bad name: $name";
    }
  }
}

#(c) Alexandr Ciornii 2010, Artistic/GPL/public domain
