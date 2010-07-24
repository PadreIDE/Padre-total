use inc::Module::Install::DSL 0.92;

name          Padre-Plugin-PerlCritic
all_from      lib/Padre/Plugin/PerlCritic.pm
requires      Padre         0.54
requires      Perl::Critic  0
test_requires Test::More    0.47
repository    http://svn.perlide.org/padre/trunk/Padre-Plugin-PerlCritic/
