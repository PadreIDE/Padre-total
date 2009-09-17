use strict;
use warnings;

my $url = 'http://github.com/cowens/perlopref/raw/master/perlopref.pod';
print "Loading $url\n";
require LWP::UserAgent;
require HTTP::Request;
my $ua = LWP::UserAgent->new;
my $req = HTTP::Request->new(GET => $url);
my $res = $ua->request($req);
if(not $res->is_success) {
	die $res->status_line, "\n";
}

require File::Spec;
my $file = File::Spec->catfile('share', 'doc', 'perlopref.pod');
if(-f $file) {
	print "Replacing perlopref.pod...\n";
	open FILE, '>:raw', $file or die "Could not open $file for writing\n";
	print FILE $res->content;
	close FILE;
} else {
	print "Could not find $file\n";
}

__END__

=head1 NAME

update_perlopref.pl - update perlopref.pod from github

=head1 DESCRIPTION

FYI, perlopref is Perl Operator Reference.

This is a simple script to obtain the latest perlopref.pod 
from github and write it in its proper Padre folder

=head1 AUTHOR

Ahmad M. Zawawi C<< <ahmad.zawawi at gmail.com> >>

=head1 COPYRIGHT AND LICENSE

Copyright 2009 C<< <ahmad.zawawi at gmail.com> >>

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl 5 itself.