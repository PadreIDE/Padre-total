#!/usr/bin/perl
use lib qw( lib );
use Data::Dumper;

$|++;

use Padre::Swarm::Transport::Multicast;
my $mc = Padre::Swarm::Transport::Multicast->new;
$mc->subscribe_channel( 12000 );
$mc->start;

while ( 1 ) {
	$mc->poll(1);
	my $buffer;
	my ($message,$frame) = $mc->receive_from( 12000 );
	print Dumper $frame;
	print Dumper $message;
}
