use strict;
use warnings;

#
# Parse an online perlopref.pod and returns a hash of topics and help
#
sub parse_perlopref {
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

	# Open perlopref
	my $fh;
	my $content = $res->content;
	open $fh, "<", \$content;


	my %index = ();

	# Add PRECEDENCE to index
	until (<$fh> =~ /=head1 PRECEDENCE/) { }

	my $line;
	while($line = <$fh>) {
		last if($line =~ /=head1 OPERATORS/);
		$index{PRECEDENCE} .= $line;
	}

	# Add OPERATORS to index
	my $op;
	while($line = <$fh>) {
		if($line =~ /=head2\s+(.+)$/) {
			$op = $1;
		} elsif($op){
			$index{$op} .= $line;
		}
	}

	# and we're done
	close $fh;

	return %index;
}

my %op_ref = parse_perlopref 'http://github.com/cowens/perlopref/raw/456675100b4e4b7fb048e7fa2b525bcf7145070c/perlopref.pod';
print "Indexed " . (scalar keys %op_ref) . " topic\n";

__END__

=head1 NAME

parse_perlopref.pl - A script to parse perlopref

=head1 DESCRIPTION

This is a simple script to load perlopref.pod from github and generate an index
which we can re-use in Padre Help Search.

=head1 AUTHOR

Ahmad M. Zawawi C<< <ahmad.zawawi at gmail.com> >>

=head1 COPYRIGHT AND LICENSE

Copyright 2009 C<< <ahmad.zawawi at gmail.com> >>

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl 5 itself.