#!/usr/bin/perl

use 5.006;
use strict;
use warnings;

use File::Spec ();
use LWP::UserAgent ();
use HTTP::Request ();

# Fetch the wxWidgets HTML documentation zip file if it is not found
my $WX_WIGDETS_HTML_ZIP = 'wxWidgets-2.8.10-HTML.zip';
unless(-e $WX_WIGDETS_HTML_ZIP) {
	# Download wxwidgets HTML documentation zip file
	my $url = 'http://garr.dl.sourceforge.net/project/wxwindows/Documents/2.8.10/wxWidgets-2.8.10-HTML.zip';
	print "Downloading $url. Please wait...\n";
	my $ua = LWP::UserAgent->new;
	my $req = HTTP::Request->new(GET => $url);
	my $res = $ua->request($req);
	if(not $res->is_success) {
		warn $res->status_line, "\n";
	}

	# Write download file to disk
	print "Writing $WX_WIGDETS_HTML_ZIP...\n";
	if(open FILE, '>:raw', $WX_WIGDETS_HTML_ZIP) {
		print FILE $res->content;
		close FILE;
	} else {
		warn "Could not open $WX_WIGDETS_HTML_ZIP for writing\n";
	}
}

exit;


#TODO unzip the file

#Define some constants
my $WX_CLASSREF = "c:/tools/temp/wx_classref.html";

# Stores a list of WX classes filenames
my @wxclasses = ();

#Step 1: Read Wx classes list from wx_classref.html
if(open(my $fh, $WX_CLASSREF)) {
	print "Opened $WX_CLASSREF\n";
	my $begin;
	while(my $line = <$fh>) {
		if($line =~ /<H2>Alphabetical class reference<\/H2>/) {
			$begin = 1;
		} elsif($begin && $line =~ /<A HREF="(.+?)#.+?"><B>(.+)?<\/B><\/A><BR>/) {
			my $wxperl_class = $2;
			$wxperl_class =~ s/wx(.+?)/Wx::$1/;
			push @wxclasses, { "file" => $1, "class" => $wxperl_class };
		}
	}
} else {
	die "Could not open $WX_CLASSREF\n";
}

print "Found " . @wxclasses . " Wx Classes to parse\n";

foreach my $wxclass (@wxclasses) {
	print $wxclass->{class} . "\n";
}

=head1 NAME

parse_wxwidgets_docs.pl - Parse wxWidgets HTML documentation

=head1 DESCRIPTION

This is a simple script to parse WxWidgets HTML documentation into something useful
that we can use of in Padre help system :)

=head1 AUTHOR

Ahmad M. Zawawi C<< <ahmad.zawawi at gmail.com> >>

=head1 COPYRIGHT AND LICENSE

Copyright 2009 C<< <ahmad.zawawi at gmail.com> >>

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl 5 itself.