#!/usr/bin/perl

use 5.010;
use strict;
use warnings FATAL => 'all';

use English qw( -no_match_vars ); # Avoids regex performance penalty
local $OUTPUT_AUTOFLUSH = 1;

if ( $OSNAME eq 'MSWin32' ) {
	require Win32::Process;
	require Win32;
	use constant NORMALPRIORITYCLASS => 0x00000020;
}

use Test::More tests => 4;
use Test::Deep;
use Time::HiRes 'sleep';

use File::Temp qw(tempdir);
my ( $host, $port, $porto, $listen, $reuse_addr );
SCOPE: {
	$host       = 'localhost';
	$port       = 24642;
	$porto      = 'tcp';
	# $listen     = 'SOMAXCONN';
	$listen     = 1;
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
	# sleep(0.01) if $OSNAME eq 'MSWin32'; #helps against extra processes after exit
	ok( $debugger->quit, 'quit with prams' );
	if ( $OSNAME eq 'MSWin32' ) {
		$pid->Kill(0) or die "Cannot kill '$pid'";
	}
}

SCOPE: {
	$host = 'localhost';
	$port = 24642;
	my ( $dir, $pid ) = run_perl5db( 't/eg/05-io.pl', $host, $port );
	require Debug::Client;
	ok( my $debugger = Debug::Client->new(), 'initialize without prams' );
	$debugger->run;
	# sleep(0.01) if $OSNAME eq 'MSWin32'; #helps against extra processes after exit
	ok( $debugger->quit, 'quit witout prams' );
	if ( $OSNAME eq 'MSWin32' ) {
		$pid->Kill(0) or die "Cannot kill '$pid'";
	}	
}

sub run_perl5db {
	my ( $file, $host, $port ) = @_;
	my $dir = tempdir( CLEANUP => 0 );
	my $path = $dir;
	my $pid;
	if ( $OSNAME eq 'MSWin32' ) {
		# require Win32;
		$path = Win32::GetLongPathName($path);
		local $ENV{PERLDB_OPTS} = "RemotePort=$host:$port";
		# sleep 1;
		sleep(0.080);
		Win32::Process::Create(
			$pid,
			$EXECUTABLE_NAME,
			# qq(perl -d $file ),
			qq(perl -d $file > "$path/out" 2> "$path/err"),
			1,
			NORMALPRIORITYCLASS,
			'.',
		) or die Win32::FormatMessage( Win32::GetLastError() );
		# system( 1, qq($OSNAME -d $file > "$path/out" 2> "$path/err") );
	} else {
		my $pid = fork();
		die if not defined $pid;
		if ( not $pid ) {
			local $ENV{PERLDB_OPTS} = "RemotePort=$host:$port";
			# sleep 1;
			sleep(0.080);
			# exec qq($EXECUTABLE_NAME -d $file );
			exec qq($EXECUTABLE_NAME -d $file > "$path/out" 2> "$path/err");
			exit 0;
		}
	}
	# return ($dir);
	return ( $dir, $pid );
}

done_testing();

__END__

Info: 06-initialize.t is effectively testing the win32/(linux, osx) bits of t/lib/Debugger.pm