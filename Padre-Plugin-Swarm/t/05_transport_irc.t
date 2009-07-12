use Test::More 'no_plan';
use constant CHAT => 13000;

use JSON::XS;
BEGIN {
use_ok( 'Padre::Swarm::Transport::IRC' );
use_ok( 'Padre::Util' );
use_ok( 'Padre::Swarm::Message' );
};


my $tr = Padre::Swarm::Transport::IRC->new(
      nickname => 'padre_swarm_test_'.$$,
      loopback => 1,
);
isa_ok( $tr, 'Padre::Swarm::Transport::IRC' );

ok( $tr->subscribe_channel( CHAT ) , 'Subscribe to a channel' );
    
ok( $tr->unsubscribe_channel( CHAT ) , 'UnSubscribe channel' );
    
$tr->subscribe_channel( CHAT );

ok( $tr->start , 'Started transport' );
ok( $tr->started, 'Transport claims to be started' );

my $channel_data = 'TEST HARNESS PING!';


ok( $tr->tell_channel( CHAT, $channel_data ) , 'Tell channel' );
my @ready = $tr->poll(15);
ok( @ready , 'Poll should return some ready handles' );
my ($message,$frame) = $tr->receive_from_channel( CHAT );
is_deeply( $message, $channel_data , 'Received channel data' );
ok( !$tr->poll() , 'Poll should have no data to read' );
poll_loop($tr);

ok( $tr->shutdown , 'Transport shutdown' );
$tr->poll(1);
ok( !$tr->started , 'Transport claims to be stopped' );


sub poll_loop {
	my $tr = shift;
	my $run = 1;
	my $i = 0;
	my @messages;
	while ($run && $i < 10) {
	    $tr->tell_channel( CHAT , $i++ );
	    while ( my @ready =$tr->poll(0.5) ) {
		    foreach my $chan ( @ready ) {
			while ( my($msg,$frame) = $tr->receive_from_channel( $chan ) )
			{
			    push @messages,$msg;
			}
		    }
	    }
	}
	ok( 10 == @messages , "total messages " .  @messages );
}

