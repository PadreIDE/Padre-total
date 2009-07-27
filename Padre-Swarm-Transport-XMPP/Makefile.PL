use inc::Module::Install::DSL 0.91;

all_from      lib/Padre/Swarm/Transport/XMPP.pm
requires      Padre::Plugin::Swarm 0.01
requires      Net::Jabber
test_requires Test::More 0.42
