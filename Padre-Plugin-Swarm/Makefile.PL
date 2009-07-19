use inc::Module::Install::DSL 0.91;

license		perl
all_from      lib/Padre/Plugin/Swarm.pm
requires      Padre      0.36
requires      IO::Socket::Multicast 1.06_01
requires      IO::Select 0
requires      Params::Util
requires      Class::XSAccessor
requires      Class::Autouse
requires	AnyEvent::IRC
requires	Guard
requires	Net::Jabber
requires	Text::Patch
test_requires Test::More 0.42
install_share	lib/Padre/Plugin/Swarm/share/
