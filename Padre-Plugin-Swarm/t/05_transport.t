use Test::More 'no_plan';
use constant CHAT => 12000;

use JSON::XS;

use_ok( 'Padre::Swarm::Transport::Multicast' );

my $tr = new Padre::Swarm::Transport::Multicast;
isa_ok( $tr, 'Padre::Swarm::Transport::Multicast' );

ok( $tr->subscribe_channel( CHAT ) , 'Subscribe to a channel' );
    
ok( $tr->unsubscribe_channel( CHAT ) , 'UnSubscribe channel' );
    
$tr->subscribe_channel( CHAT );

ok( $tr->start , 'Started transport' );
ok( $tr->started, 'Transport claims to be started' );

my $channel_data = 
  JSON::XS::encode_json(
	{ message=>'Hello World!', from=>'test' }
  );

ok( $tr->tell_channel( CHAT, $channel_data ) , 'Tell channel' );

my @ready = $tr->poll;
ok( @ready , 'Poll should return some ready handles' );
my ($message,$frame) = $tr->receive_from( CHAT );
is_deeply( $message, $channel_data , 'Received channel data' );
ok( !$tr->poll(1) , 'Poll should have no data to read' );
ok( $tr->shutdown , 'Transport shutdown' );