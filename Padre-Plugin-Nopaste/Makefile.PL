use inc::Module::Install::DSL 1.06;

all_from      lib/Padre/Plugin/Nopaste.pm
requires_from lib/Padre/Plugin/Nopaste.pm
requires_from lib/Padre/Plugin/Nopaste/Task.pm

requires Padre					0.96
requires App::Nopaste			0.35
requires Try::Tiny				0.11

test_requires Test::More	  		0.98
test_requires Test::Pod				1.45
test_requires Test::Pod::Coverage	1.08

no_index directory	qw{ t xt eg share inc privinc }
homepage		http://padre.perlide.org/trac/wiki/PadrePluginNopaste
bugtracker		http://padre.perlide.org/trac
repository		http://svn.perlide.org/padre/trunk/Padre-Plugin-Nopaste/
install_share

