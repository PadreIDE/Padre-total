#!/usr/bin/perl
use lib qw( lib );
$|++;

use Padre::Swarm::Transport::Multicast;
my $mc = Padre::Swarm::Transport::Multicast->new;
$mc->subscribe_channel( 12000 );
$mc->start;

while ( 1 ) {
	$mc->poll(1);
	my $buffer;
	my ($channel,$client,$payload) = $mc->receive_from( 12000 );
	print "[$client], $payload";
}