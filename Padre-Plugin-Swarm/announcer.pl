#!/usr/bin/perl
use lib qw( lib );
$|++;

use Padre::Swarm::Transport::Multicast;
my $mc = Padre::Swarm::Transport::Multicast->new;
$mc->subscribe_channel( 12000 );
$mc->start;

while ( <STDIN> ) {
	chomp;
	$mc->tell_channel( 12000, $_ );
}