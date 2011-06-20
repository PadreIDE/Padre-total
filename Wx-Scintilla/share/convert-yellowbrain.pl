use strict;
use warnings;


# auto flush STDOUT
$| = 1;

my $index_html = download_url('http://www.yellowbrain.com/stc/index.html', 'index.html');
my @index_html_lines = split /\n/, $index_html;
my $subject_index_pattern = quotemeta q{<a name="subjdex">};
my $alpha_index_pattern = quotemeta q{<a name="alphadex"><b>Alphabetic Index</b></a></font></p>};
my $parse_subject_index = 0;
foreach my $line (@index_html_lines) {
	if($line =~ /$subject_index_pattern/) {
		$parse_subject_index = 1;
	} elsif($line =~ /$alpha_index_pattern/) {
		$parse_subject_index = 0;
	} elsif($parse_subject_index) {
		if($line =~ /<a href\="(.+?)">(.+?)<\/a>/) {
			print $1 . " => " . $2 . "\n";
		}
	}
}

#use Pod::HTML2Pod;
#print Pod::HTML2Pod::convert(
#    'file' => 'index.html',  # input file
#    'a_href' => 1,  # try converting links
#);


sub download_url {
	my $url = shift;
	my $file = shift;

	require File::Spec;
	require LWP::UserAgent;
	require HTTP::Request;

	print "Loading $url\n";
	my $ua  = LWP::UserAgent->new;
	my $req = HTTP::Request->new( GET => $url );
	my $res = $ua->request($req);
	if ( not $res->is_success ) {
		warn $res->status_line, "\n";
	}

	return $res->content;
}

__END__

=head1 NAME

convert-yellowbrain.pl - Convert yellow brain documentation to POD

=head1 AUTHOR

Ahmad M. Zawawi C<< <ahmad.zawawi at gmail.com> >>

=head1 COPYRIGHT AND LICENSE

Copyright 2011 Ahmad M. Zawawi

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl 5 itself.
