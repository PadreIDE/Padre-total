use Test::More 'no_plan';

use JSON::XS;
use t::lib::Demo;
	use threads;
	use threads::shared;
BEGIN {
use_ok( 'Padre::TaskManager' );
use_ok( 'Padre::Swarm::Service::Chat' );
use_ok( 'Padre::Swarm::Transport::Multicast' );
use_ok( 'Padre::Swarm::Message' );
}

my $app = Padre->new;
isa_ok($app, 'Padre');
my $tm = Padre::TaskManager->new;

#Padre::Util::set_logging( 1 );
#Padre::Util::set_tracing( 1 );
my $chat = Padre::Swarm::Service::Chat->new(
	use_transport => {
		'Padre::Swarm::Transport::Multicast' => {},
	}
);
$chat->schedule;

my $got_loopback : shared = 0 ;
Wx::Event::EVT_COMMAND( $app->wx->main , -1 , $chat->event,
 sub { diag "LOOPBACK!" ; $got_loopback = 1 }
);
diag( "WX event is " . $chat->event );

$chat->queue->enqueue(
	Padre::Swarm::Message->new(
		{from=>getlogin(),type=>'chat',body=>'test'}
	)
);

sleep 5;

ok( $got_loopback , 'got service event' );

$chat->queue->enqueue('HANGUP');
$chat->shutdown;
$tm->cleanup;
#ok( $chat->start, 'Started chat' );
#ok( $chat->shutdown , 'Chat shutdown' );