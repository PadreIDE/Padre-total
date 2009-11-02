#!/usr/bin/perl
use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 13;

use IO::Socket::Multicast;

sub test {
  my ($flag,$test) = @_;
  print $flag ? "ok $test\n" : "not ok $test ($!)\n";
}

my $s = IO::Socket::Multicast->new;

# dumb tests for incompatibilities, etc.
my $io_interface_avail = eval "use IO::Interface ':flags'; 1;";
my $mcast_if = $io_interface_avail && find_a_mcast_if($s);
my ($linux_version) = `uname -sr` =~ /^Linux (\d+\.\d+)/;
my $os_ok = $linux_version && ($linux_version >= 2.2);
my $win32 = $^O =~ /^MSWin/;

ok($s->mcast_add('225.0.1.1'), 'Add socket to Multicast Group' );
ok($s->mcast_drop(inet_aton('225.0.1.1')),'Drop Multicast Group' );
if ($win32) {
  print "ok # Skip. Doesn't work on Win32??\n";
  # What the hell ? Dropping an unsubscribed mcast group on win32 fails to fail?
} else {
  ok(!$s->mcast_drop('225.0.1.1'), 'Drop unsubscribed group returns false'  );
}

SKIP: {
if ($os_ok) {
  ok($s->mcast_ttl         == 1,     'Get socket TTL default is one');
  ok($s->mcast_ttl(10)     == 1,     'Set TTL returns previous value');
  ok($s->mcast_ttl         == 10,    'Get TTL post-set returns correct TTL');
  ok($s->mcast_loopback    == 1,     'Multicast loopback defaults to true');
  ok($s->mcast_loopback(0) == 1,     'Loopback set returns previous value' );
  ok($s->mcast_loopback    == 0,   'Loopback get' );
} else {
  skip  "Needs Linux >= 2.2\n", 6;
  }
}

if ($io_interface_avail && $mcast_if && $os_ok) {
  ok ($s->mcast_if  eq 'any'    ,    'Default interface "any"');
  ok ($s->mcast_if($mcast_if) eq 'any', 'Multicast interface set returns previous value');
  ok ($s->mcast_if eq $mcast_if       , 'Multicast interface set');
  ok ($s->mcast_add('225.0.1.1',$mcast_if)  , 'Multicast add GROUP,if');
} else {
  my $explanation = 'IO::Interface not available' if !$io_interface_avail;
  $explanation ||= 'No multicast interface available'  if !$mcast_if;
  $explanation ||= 'Needs Linux >= 2.2'        if !$os_ok;
  skip $explanation , 4;
}

sub find_a_mcast_if {
  my $s = shift;
  my @ifs = $s->if_list;
  foreach (reverse @ifs) {
    
    next unless $s->if_flags($_) & IFF_MULTICAST();
    next unless $s->if_flags($_) & IFF_RUNNING();
    next unless $s->if_addr($_); 
    return $_;
  }
}
