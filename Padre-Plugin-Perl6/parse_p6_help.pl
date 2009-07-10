use strict;
use warnings;

#autoflush STDOUT
$| = 1;

#
# Convert html back to text by removing html tags and converting
# html entities.
#
sub _to_text {
	my $text = shift;
	$text =~ s/<em>(.+?)<\/em>/$1/g;
	$text =~ s/<.+?>//g;
	$text =~ s/&amp;/&/g;
	$text =~ s/&lt;/</g;
	$text =~ s/&gt;/>/g;
	$text =~ s/&quot;/"/g;
	$text =~ s/&nbsp;/ /g;
	return $text;
}

#
# Converts Perl 6 table index help to POD after getting it from the web.
#
sub _perl6_table_index_to_pod {
	my $url = shift;
	
	print "Loading $url\n";
	require LWP::UserAgent;
	require HTTP::Request;
	my $ua = LWP::UserAgent->new;
	my $req = HTTP::Request->new(GET => $url);
	my $res = $ua->request($req);
	if(not $res->is_success) {
		die $res->status_line, "\n";
	}
	
	my $pod = '';
	my @lines = split /\n/, $res->content;
	foreach my $line (@lines) {
		chomp $line;
		if($line =~ /<li><strong>(.+?)<\/strong>(.+?)<\/li>/) {
			my ($item, $item_description)= (_to_text($1), _to_text($2) );
			$pod .=  "=head1 $item\n\n$item_description\n\n";
		}
	}
	
	return $pod;
}

my $pod = _perl6_table_index_to_pod 'http://www.perlfoundation.org/perl6/index.cgi?perl_table_index';
my $filename = 'lib/Padre/Plugin/Perl6/perl6_table_index.pod';
print "Writing to $filename\n";
open FILE, ">$filename" or die "Cannot open $filename for writing\n";
print FILE $pod;
close FILE;

print "\n\n----- FINISHED -----\n\n";

# Copyright 2008-2009 Ahmad M. Zawawi and Gabor Szabo.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.