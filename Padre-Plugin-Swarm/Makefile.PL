use inc::Module::Install::DSL 0.91;

all_from      lib/Padre/Plugin/Swarm.pm
requires      Padre      0.36
requires      IO::Socket::Multicast 1.06_01
requires      IO::Select 0
requires      Params::Util
requires      Class::XSAccessor
requires      Class::Autouse
requires	AnyEvent::IRC
test_requires Test::More 0.42
install_share	lib/Padre/Plugin/Swarm/share/
