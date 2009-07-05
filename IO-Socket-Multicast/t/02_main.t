#!/usr/bin/perl

BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 14;
use IO::Socket::Multicast;

my $s = IO::Socket::Multicast->new;
isa_ok( $s, 'IO::Socket::Multicast' );

# Dumb tests for incompatibilities, etc.
my $io_interface_avail = eval "use IO::Interface ':flags'; 1;";
my $mcast_if = $io_interface_avail && find_a_mcast_if($s);
my $win32 = $^O =~ /^MSWin/;
my $linux_version = 0;
unless ( $win32 ) {
	($linux_version) = `uname -sr` =~ /^Linux (\d+\.\d+)/;
}
my $os_ok = ! $linux_version || ($linux_version >= 2.2);

SKIP: {
	skip('Not applicable to Win32', 3) if $win32;
	ok( $s->mcast_add('225.0.1.1') );
	ok( $s->mcast_drop(inet_aton('225.0.1.1')) );
	ok( ! $s->mcast_drop('225.0.1.1') );
}
SKIP: {
	skip('Not applicable to this OS', 6 ) unless $os_ok;
	ok( $s->mcast_ttl         == 1  );
	ok( $s->mcast_ttl(10)     == 1  );
	ok( $s->mcast_ttl         == 10 );
	ok( $s->mcast_loopback    == 1  );
	ok( $s->mcast_loopback(0) == 1  );
	ok( $s->mcast_loopback    == 0  );
}
SKIP: {
	skip( 'IO::Interface not available', 4 ) unless $io_interface_avail;
	skip( 'No multicast interface available', 4 ) unless $mcast_if;
	skip( 'Needs Linux >= 2.2', 4 ) unless $os_ok;
	ok( $s->mcast_if  eq 'any' );
	ok( $s->mcast_if($mcast_if) eq 'any' );
	ok( $s->mcast_if eq $mcast_if );
	ok( $s->mcast_add('225.0.1.1',$mcast_if) );
}

sub find_a_mcast_if {
  my $s = shift;
  my @ifs = $s->if_list;
  foreach (@ifs) {
    next unless $s->if_flags($_) & IFF_MULTICAST();
    next unless $s->if_flags($_) & IFF_RUNNING();
    return $_;
  }
}
