use strict;
use warnings;

require File::Spec;
require LWP::UserAgent;
require HTTP::Request;

# List of files to update
my @files = (
	'Artistic',
	'Copying',
	'README',
	'perlopref.pod',
);

# Download all files and write them to disk
for my $file (@files) {
	
	# Load file from perlopref's github project
	my $url = "http://github.com/cowens/perlopref/raw/master/$file";
	print "Loading $url\n";
	my $ua = LWP::UserAgent->new;
	my $req = HTTP::Request->new(GET => $url);
	my $res = $ua->request($req);
	if(not $res->is_success) {
		warn $res->status_line, "\n";
	}

	# Write file to disk
	my $file = File::Spec->join('share', 'doc', 'perlopref', $file);
	print "Writing $file...\n";
	if(open FILE, '>:raw', $file) {
		print FILE $res->content;
		close FILE;
	} else {
		warn "Could not open $file for writing\n";
	}
}

__END__

=head1 NAME

update_perlopref.pl - update perlopref.pod from github

=head1 DESCRIPTION

FYI, perlopref is Perl Operator Reference.

This is a simple script to obtain the latest perlopref files 
from github and write it in its proper Padre folder

=head1 AUTHOR

Ahmad M. Zawawi C<< <ahmad.zawawi at gmail.com> >>

=head1 COPYRIGHT AND LICENSE

Copyright 2009 C<< <ahmad.zawawi at gmail.com> >>

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl 5 itself.