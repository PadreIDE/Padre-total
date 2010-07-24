#!/usr/bin/perl

use 5.006;
use strict;
use warnings;

use File::Temp       ();
use File::Spec       ();
use LWP::UserAgent   ();
use HTTP::Request    ();
use Archive::Extract ();

my $WX_WIGDETS_HTML_ZIP = 'wxWidgets-2.8.10-HTML.zip';

# Step 1: Fetch the wxWidgets HTML documentation zip file if it is not found
unless(download_wxwidgets_html_zip()) {
	die "wxWidget HTML zip file is not found!\n";
}

# Step 2: unzip the html zip file
my $dir = File::Temp->newdir;
unzip_file($dir);

# Step 3: Read WX Classes list index file
my @wxclasses = read_wx_classes_list($dir);
print "Found " . @wxclasses . " Wx Classes to parse\n";

# foreach my $wxclass (@wxclasses) {
	# print $wxclass->{class} . "\n";
# }
 
exit;

#
# Download wxwidgets HTML documentation zip file
#
sub download_wxwidgets_html_zip {
	unless(-e $WX_WIGDETS_HTML_ZIP) {
		my $url = 'http://garr.dl.sourceforge.net/project/wxwindows/Documents/2.8.10/$WX_WIGDETS_HTML_ZIP';
		print "Downloading $url. Please wait...\n";
		my $ua = LWP::UserAgent->new;
		my $req = HTTP::Request->new(GET => $url);
		my $res = $ua->request($req);
		if(not $res->is_success) {
			die $res->status_line, "\n";
		}

		# Write download file to disk
		print "Writing $WX_WIGDETS_HTML_ZIP...\n";
		if(open FILE, '>:raw', $WX_WIGDETS_HTML_ZIP) {
			print FILE $res->content;
			close FILE;
		} else {
			die "Could not open $WX_WIGDETS_HTML_ZIP for writing\n";
		}
	}

	return -e $WX_WIGDETS_HTML_ZIP;
}

#
# Unzip the HTML zip file
#
sub unzip_file {
	my $dir = shift;

	my $zip = Archive::Extract->new( archive => $WX_WIGDETS_HTML_ZIP );
	die "$WX_WIGDETS_HTML_ZIP is not a zip file\n" unless ($zip->is_zip);
	print "Extracting $WX_WIGDETS_HTML_ZIP to $dir...\n";
	$zip->extract(to => $dir) or die $zip->error;
}

exit;

#
# Read WX classes list index from docs/mshtml/wx/wx_classref.html
#
sub read_wx_classes_list {
	my $dir = shift;
	
	my $wx_classref = File::Spec->join($dir, 'docs', 'mshtml', 'wx', 'wx_classref.html');

	# Stores a list of WX classes filenames
	my @wxclasses = ();

	#Step 1: Read Wx classes list from wx_classref.html
	if(open(my $fh, $wx_classref)) {
		print "Opened $wx_classref\n";
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
		die "Could not open $wx_classref\n";
	}

	return @wxclasses;
}

__END__

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