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

print $res->content;

__END__

=head1 NAME

update_perlopref.pl - A script to download the latest copy of perlopref.pod from github

=head1 DESCRIPTION

This is a simple script to load perlopref.pod from github and write it in its 
proper Padre folder

=head1 AUTHOR

Ahmad M. Zawawi C<< <ahmad.zawawi at gmail.com> >>

=head1 COPYRIGHT AND LICENSE

Copyright 2009 C<< <ahmad.zawawi at gmail.com> >>

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl 5 itself.