#!/usr/bin/perl

use 5.006;
use strict;
use warnings;
use Test::More tests => 1;
use Hyppolit;

ok( defined(%Hyppolit::Channel_Text), 'Check RegExp-array' );

sub Check {
 my @Matches;
 my $Number;
 for (keys(%Hyppolit::Channel_Text)) {
  $_[0] =~ /$_/ or next;
  push @Matches,$Hyppolit::Channel_Text->{$_};
  $Number = $1;
 }
 if (defined($_[1])) {
  ok($#Matches == 0,$_[0].': Match count');
  ok($Matches[0] eq $_[1],$_[0].': Check match')
  ok($Number == $_[2],$_[0].': Check number')
 } else {
  ok($#Matches == -1,$_[0].': Match count');
 }
}

# Check tickets
&Check('#123','trac_ticket_text',123);
&Check('\#123');

# Check changesets
&Check('r123','trac_changeset_text',123);
&Check('border123');
