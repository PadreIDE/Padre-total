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
	'perlopquick.pod',
);

my $dir = File::Spec->join( 'share', 'doc', 'perlopquick' );
unless ( -d $dir ) {
	die "Abort! I could not find share/doc/perloquick in the current directory\n";
}

# Download all files and write them to disk
for my $file (@files) {

	# Load file from perlopquick's github project
	my $url = "http://github.com/cowens/perlopquick/raw/master/$file";
	print "Loading $url\n";
	my $ua  = LWP::UserAgent->new;
	my $req = HTTP::Request->new( GET => $url );
	my $res = $ua->request($req);
	if ( not $res->is_success ) {
		warn $res->status_line, "\n";
	}

	# Write file to disk
	my $file = File::Spec->join( $dir, $file );
	print "Writing $file...\n";
	if ( open FILE, '>:raw', $file ) {
		print FILE $res->content;
		close FILE;
	} else {
		warn "Could not open $file for writing\n";
	}
}

__END__

=head1 NAME

update_perlopquick.pl - update perlopquick.pod from github

=head1 DESCRIPTION

The perlopquick POD document is a quick reference for the various Perl
operators.  It is organized by operator, sorted by precedence groups (inside of
a precedence group there is no sorting).

This is a simple script fetches the latest github perlopquick files
and stores it into its proper Padre folder

=head1 AUTHOR

Ahmad M. Zawawi C<< <ahmad.zawawi at gmail.com> >>

=head1 COPYRIGHT AND LICENSE

Copyright 2009 C<< <ahmad.zawawi at gmail.com> >>

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl 5 itself.
