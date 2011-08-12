use Test::More tests => 1;
use Padre::Plugin::Swarm::Transport::Global;

my $bailout = AnyEvent->condvar;

my $t = new Padre::Plugin::Swarm::Transport::Global
                host => 'swarm.perlide.org',
                port => 12000;
my $timeout = AnyEvent->timer( after=>10 , cb=>sub{ $bailout->croak('timeout') } );

$t->reg_cb( connect => sub {  ok('Connected'); $bailout->send; } );
$t->reg_cb( disconnect => sub { ok('Disconnected') ; $bailout->send } );
$t->enable;

$bailout->recv;

