use inc::Module::Install::DSL 0.91;

all_from      lib/Padre/Plugin/Swarm.pm
requires      Padre                 0.36
requires      IO::Socket::Multicast 1.07_02
requires      IO::Select
requires      Params::Util          1.00
requires      Class::XSAccessor     1.03
requires      AnyEvent::IRC
requires      Guard                 1.01
requires      Text::Patch           1.04
test_requires Test::More            0.42
no_index      junkyard
install_share
