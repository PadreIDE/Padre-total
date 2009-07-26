use inc::Module::Install::DSL 0.91;

all_from      lib/Padre/Plugin/Swarm.pm
requires      Padre                 0.36
requires      IO::Socket::Multicast 1.06_01
requires      IO::Select
requires      Params::Util          1.00
requires      Class::XSAccessor     1.03
requires      AnyEvent::IRC
requires      Guard
requires      Net::Jabber
requires      Text::Patch           1.04
no_index      junkyard
test_requires Test::More            0.42
install_share lib/Padre/Plugin/Swarm/share
