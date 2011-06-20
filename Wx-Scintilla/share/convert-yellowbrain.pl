use strict;
use warnings;
use Pod::HTML2Pod;
use File::Spec ();

# auto flush STDOUT
$| = 1;

my $stc_base_url = 'http://www.yellowbrain.com/stc';
my $index_html = download_url("$stc_base_url/index.html", 'index.html');
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
			my ($file, $topic) = ($1, $2);
			print "Loading $topic\n";
			my $contents = download_url("$stc_base_url/$file", $file);
			$file =~ s/\.html/.pod/;
			$file = File::Spec->catfile('doc', $file);
			if(open my $fh, '>', $file) {
				print $fh Pod::HTML2Pod::convert(
				    'content' => $contents,  # input file
				);
				close $fh;
			} else {
				die "Could open $file for writing\n";
			}	
		}
	}
}




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
