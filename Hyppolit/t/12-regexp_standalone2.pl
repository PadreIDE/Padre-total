#!/usr/bin/perl

sub Check {
 my $Text = shift;
 my $Result = shift;
 my $Number = shift;

 print "---[$Text]---\n";

 print "\tticket result: ".($Text =~ /(?<!\\)\#(\d+)/)." ($1/$2)\n";

 print "\tchangeset result: ".($Text =~ /\br(\d+)/)." ($1/$2)\n";

 print "\n";
}

&Check('#123','trac_ticket_text',123);
&Check('\#123',undef);

# Check changesets
&Check('r123','trac_changeset_text',123);
&Check('border123',undef);
