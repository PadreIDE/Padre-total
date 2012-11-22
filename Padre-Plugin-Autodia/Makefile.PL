use inc::Module::Install::DSL 1.06;

all_from lib/Padre/Plugin/Autodia.pm
requires_from lib/Padre/Plugin/Autodia.pm

perl_version 5.010_001

requires Autodia         2.14
requires Carp            1.26
requires Cwd             3.33
requires Data::Printer   0.34
requires File::Spec      3.33
requires GraphViz        2.14
requires Padre           0.96
requires Try::Tiny       0.11

test_requires Test::More  0.98

homepage    http://padre.perlide.org/trac/wiki/PadrePluginAutodia
bugtracker  http://padre.perlide.org/trac/wiki/Tickets
repository  http://svn.perlide.org/padre/trunk/Padre-Plugin-Autodia/

no_index directory  qw{ t xt eg share inc privinc }
