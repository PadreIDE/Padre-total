#!/usr/bin/env perl

use v5.10;
use strict;
use warnings;

# Turn on $OUTPUT_AUTOFLUSH
$| = 1;

use Test::More;
use Test::Deep;

plan( tests => 4 );

use File::Temp qw(tempdir);
my ( $host, $port, $porto, $listen, $reuse_addr );

{
	$host       = 'localhost';
	$port       = 24642;
	$porto      = 'tcp';
	$listen     = 'SOMAXCONN';
	$reuse_addr = 1;
	my ( $dir, $pid ) = run_perl5db( 't/eg/05-io.pl', $host, $port );
	require Debug::Client;
	ok( my $debugger = Debug::Client->new(
			host   => $host,
			port   => $port,
			porto  => $porto,
			listen => $listen,
			reuse  => $reuse_addr
		),
		'initialize with prams'
	);
	$debugger->run;
	ok( $debugger->quit, 'quit with prams' );
}

{
	$host = 'localhost';
	$port = 24642;
	my ( $dir, $pid ) = run_perl5db( 't/eg/05-io.pl', $host, $port );
	require Debug::Client;
	ok( my $debugger = Debug::Client->new(), 'initialize without prams' );
	$debugger->run;
	ok( $debugger->quit, 'quit witout prams' );
}

sub run_perl5db {
	my ( $file, $host, $port ) = @_;
	my $dir = tempdir( CLEANUP => 0 );
	my $path = $dir;
	if ( $^O =~ /Win32/i ) {
		require Win32;
		$path = Win32::GetLongPathName($path);
		local $ENV{PERLDB_OPTS} = "RemotePort=$host:$port";
		sleep 1;
		system( 1, qq($^X -d $file > "$path/out" 2> "$path/err") );
	} else {
		my $pid = fork();
		die if not defined $pid;
		if ( not $pid ) {
			local $ENV{PERLDB_OPTS} = "RemotePort=$host:$port";
			sleep 1;
			exec qq($^X -d $file > "$path/out" 2> "$path/err");
			exit 0;
		}
	}
	return ($dir);
}

done_testing();

1;

__END__
