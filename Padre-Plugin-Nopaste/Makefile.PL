use inc::Module::Install::DSL 1.06;

perl_version 5.010001

all_from      lib/Padre/Plugin/Nopaste.pm
requires_from lib/Padre/Plugin/Nopaste.pm

requires App::Nopaste 0.91
requires Carp         1.26
requires Moo          1.000008
requires Padre        0.96
requires Try::Tiny    0.12
requires constant     1.25
requires parent       0.225
requires strictures   1.004004

test_requires Test::More 0.98

recommends Test::Pod           1.46
recommends Test::Pod::Coverage 1.08

homepage		http://padre.perlide.org/trac/wiki/PadrePluginNopaste
bugtracker		http://padre.perlide.org/trac
repository		http://svn.perlide.org/padre/trunk/Padre-Plugin-Nopaste/

no_index directory	qw{ inc share t xt }

install_share

