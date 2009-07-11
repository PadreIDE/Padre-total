use Test::More 'no_plan';

use JSON::XS;

BEGIN {
	use threads;
	use threads::shared;
use_ok( 'Padre' );
# Create the object so that Padre->ide works
my $app = Padre->new;
isa_ok($app, 'Padre');

use_ok( 'Padre::TaskManager' );
use_ok( 'Padre::Swarm::Service::Chat' );
use_ok( 'Padre::Swarm::Transport::XMPP' );
}

#Padre::Util::set_logging( 1 );
#Padre::Util::set_tracing( 1 );

my $tm = Padre::TaskManager->new();

my $chat = Padre::Swarm::Service::Chat->new(
	use_transport => {
		'Padre::Swarm::Transport::XMPP' => {
			nickname => 'swarm_'.$$ ,
			credentials => {
			}
		},
	}
);

$chat->schedule;
$chat->queue->enqueue({type=>'chat',message=>'test'});

sleep 30; # sooo long
$chat->queue->enqueue('HANGUP');
$chat->shutdown;

$tm->cleanup;

ok( $chat->start, 'Started chat' );
ok( $chat->shutdown , 'Chat shutdown' );
