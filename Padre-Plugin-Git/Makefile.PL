use inc::Module::Install::DSL 1.06;

all_from lib/Padre/Plugin/Git.pm
requires_from lib/Padre/Plugin/Git.pm

requires File::Which  1.09
requires Try::Tiny    0.11
requires Pithub       0.01014

test_requires Test::More  0.98

homepage    http://padre.perlide.org
bugtracker  http://padre.perlide.org/trac/wiki/Tickets
repository  http://svn.perlide.org/padre/trunk/Padre-Plugin-Git/

no_index directory            qw{ t xt eg share inc privinc }