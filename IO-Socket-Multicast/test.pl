# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

use lib './blib/lib','./blib/arch';

BEGIN { $| = 1; print "1..14\n"; }
END {print "not ok 1\n" unless $loaded;}
use IO::Socket::Multicast;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

sub test {
  my ($flag,$test) = @_;
  print $flag ? "ok $test\n" : "not ok $test ($!)\n";
}

my $s = IO::Socket::Multicast->new;

# dumb tests for incompatibilities, etc.
my $io_interface_avail = eval "use IO::Interface ':flags'; 1;";
my $mcast_if = $io_interface_avail && find_a_mcast_if($s);
my ($linux_version) = `uname -sr` =~ /^Linux (\d+\.\d+)/;
my $os_ok = !$linux_version || ($linux_version >= 2.2);
my $win32 = $^O =~ /^MSWin/;

test ($s->mcast_add('225.0.1.1'),     2);
test ($s->mcast_drop(inet_aton('225.0.1.1')),    3);
if ($win32) {
  print "ok 4 # Skip. Doesn't work on Win32\n";
} else {
  test (!$s->mcast_drop('225.0.1.1'),   4);
}

if ($os_ok) {
  test ($s->mcast_ttl         == 1,     5);
  test ($s->mcast_ttl(10)     == 1,     6);
  test ($s->mcast_ttl         == 10,    7);
  test ($s->mcast_loopback    == 1,     8);
  test ($s->mcast_loopback(0) == 1,     9);
  test ($s->mcast_loopback    == 0,    10);
} else {
  print "ok $_ # Skip. Needs Linux >= 2.2\n"
    foreach (5..10);
}

if ($io_interface_avail && $mcast_if && $os_ok) {
  test ($s->mcast_if  eq 'any'    ,    11);
  test ($s->mcast_if($mcast_if) eq 'any', 12);
  test ($s->mcast_if eq $mcast_if       , 13);
  test ($s->mcast_add('225.0.1.1',$mcast_if)  , 14);
} else {
  my $explanation = 'IO::Interface not available' if !$io_interface_avail;
  $explanation ||= 'No multicast interface available'  if !$mcast_if;
  $explanation ||= 'Needs Linux >= 2.2'        if !$os_ok;
  print "ok $_ # Skip. $explanation\n"
    foreach (11..14);
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
