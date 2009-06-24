use Test::More 'no_plan';

use_ok( 'Padre::Swarm::Transport::Multicast' );

my $tr = new Padre::Swarm::Transport::Multicast;
isa_ok( $tr, 'Padre::Swarm::Transport::Multicast' );

ok( $tr->subscribe_channel( 10000 ) , 'Subscribe to a channel' );
    
ok( $tr->unsubscribe_channel( 10000 ) , 'UnSubscribe channel' );
    
$tr->subscribe_channel( 10000 );

ok( $tr->start , 'Started transport' );
ok( $tr->started, 'Transport claims to be started' );

my $channel_data = 'Hello World!';
ok( $tr->tell_channel( 10000, $channel_data ) , 'Tell channel' );

my @ready = $tr->poll;
ok( @ready , 'Poll should return some ready handles' );

my ($port,$ip,$data) = $tr->receive_from( 10000 );
cmp_ok( $data , 'eq', $channel_data , 'Received channel data' );
ok( !$tr->poll(1) , 'Poll should have no data to read' );
ok( $tr->shutdown , 'Transport shutdown' );