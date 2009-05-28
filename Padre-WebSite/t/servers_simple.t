use strict;
use warnings;

use File::Temp qw(tempdir);
use DBI;

my $dir = tempdir( CLEANUP => 1 );

my $pid = fork();
die "Could not fork" if not defined $pid;

if (not $pid) {
	setup_database();
	run_server();

	sleep 10;
	exit;
}

# wait for the server to start
sleep 2;

require Test::More;
import Test::More;

plan(tests => 1);
diag("Dir: $dir");
diag("PID: $pid");

ok(1);

END {
	kill 9, $pid;
}

# loop:
#    send reqest
#    check response
#    check database

sub _slurp {
	my $file = shift;
	open my $fh, '<', $file or die;
	local $/ = undef;
	return <$fh>;
}

sub setup_database {
	my $schema = _slurp('schema/padre.sql');
	my $dbh = DBI->connect("dbi:SQLite:dbname=$dir/padre.db","","");
	foreach my $sql (split /;/, $schema) {
		$dbh->do($sql) if $sql =~ /\S/;
	}
	return;
}


	my $url = 'http://padre.local/cgi/collector.pl';
	my %data = (
	   version => 3.12,
	   OS => "Windows & co",
	);

	client($url, '123', \%data);

sub client {
	my ($url, $hostid, $data) = @_;
	
	require LWP;
	require HTTP::Request;
	require YAML::Tiny;
	require URI::Escape;

	my $content = "hostid=$data{hostid}&data=" . URI::Escape::uri_escape(YAML::Tiny::Dump(\%data));
	my $request = HTTP::Request->new('POST', $url);
	$request->header('Content-Type' => 'application/x-www-form-urlencoded');
	$request->header('Content-Length' => length($content));
	$request->content($content);

	my $ua = LWP::UserAgent->new;
	my $response = $ua->request($request);

	return $response->decoded_content; 
}

