#!/usr/bin/perl

use LWP::UserAgent;

my $ua = LWP::UserAgent->new;

if ( $#ARGV < 1 ) {
	print "Syntax: $0 <nick> <subject of paste>\n";
	exit 1;
}

my %data = (
	channel => '#padre',
	nick    => shift(@ARGV),
	summary => join( ' ', @ARGV ),
	paste   => join( '', <STDIN> ),
);

my $req = HTTP::Request->new( POST => 'http://paste.scsys.co.uk/paste' );
$req->content_type('application/x-www-form-urlencoded');
$req->content(
	join(
		'&',
		map {
			my $Val = $data{$_};
			$Val =~ s/(\W)/"%".uc(unpack("H*",$1))/ge;
			$Val =~ s/\%20/\+/g;
			$_ . '=' . $Val;
			} ( keys(%data) )
	)
);

my $result = $ua->request($req);
