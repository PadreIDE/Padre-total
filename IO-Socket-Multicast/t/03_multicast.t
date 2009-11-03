#!/usr/bin/perl
use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 13;
use IO::Socket::Multicast;

# Simple constructor
my $s = IO::Socket::Multicast->new;
isa_ok( $s, 'IO::Socket::Multicast' );

# Platform compatibility
my $WIN32        = $^O eq 'MSWin32';
my $LINUX        = $WIN32 ? 0 : (`uname -sr` =~ /^Linux (\d+\.\d+)/)[0];
my $OS_OK        = ( $LINUX and $LINUX >= 2.2 );
my $IO_INTERFACE = eval "use IO::Interface ':flags'; 1;";
my $INTERFACE    = $IO_INTERFACE && find_a_mcast_if($s);

# Some basics
ok($s->mcast_add('225.0.1.1'), 'Add socket to Multicast Group' );
ok($s->mcast_drop(inet_aton('225.0.1.1')),'Drop Multicast Group' );
SKIP: {
	# What the hell ? Dropping an unsubscribed mcast group on win32 fails to fail?
	skip("Doesn't work on Win32??", 1) if $WIN32;
	ok( ! $s->mcast_drop('225.0.1.1'), 'Drop unsubscribed group returns false' );
}

# More subtle control
SKIP: {
	skip("Needs Linux >= 2.2", 6) unless $OS_OK;
	ok($s->mcast_ttl         == 1,  'Get socket TTL default is one');
	ok($s->mcast_ttl(10)     == 1,  'Set TTL returns previous value');
	ok($s->mcast_ttl         == 10, 'Get TTL post-set returns correct TTL');
	ok($s->mcast_loopback    == 1,  'Multicast loopback defaults to true');
	ok($s->mcast_loopback(0) == 1,  'Loopback set returns previous value' );
	ok($s->mcast_loopback    == 0,  'Loopback get' );
}

SKIP: {
	skip('IO::Interface not available', 4)      unless $IO_INTERFACE;
	skip('No multicast interface available', 4) unless $INTERFACE;
	skip('Needs Linux >= 2.2', 4)               unless $OS_OK;
	ok ($s->mcast_if  eq 'any' ,    'Default interface "any"');
	ok ($s->mcast_if($INTERFACE) eq 'any', 'Multicast interface set returns previous value');
	ok ($s->mcast_if eq $INTERFACE , 'Multicast interface set');
	ok ($s->mcast_add('225.0.1.1',$INTERFACE), 'Multicast add GROUP,if');
}

sub find_a_mcast_if {
	my $s   = shift;
	my @ifs = $s->if_list;
	foreach ( reverse @ifs ) {
		next unless $s->if_flags($_) & IFF_MULTICAST();
		next unless $s->if_flags($_) & IFF_RUNNING();
		next unless $s->if_addr($_); 
		return $_;
	}
}
