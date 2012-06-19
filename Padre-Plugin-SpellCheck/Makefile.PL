use inc::Module::Install::DSL 1.04;

all_from      lib/Padre/Plugin/SpellCheck.pm
requires_from lib/Padre/Plugin/SpellCheck.pm
requires_from lib/Padre/Plugin/SpellCheck/Checker.pm
requires_from lib/Padre/Plugin/SpellCheck/Engine.pm
requires_from lib/Padre/Plugin/SpellCheck/Preferences.pm

requires Padre				0.96
requires Module::Util		1.07
requires Class::Accessor	0.34
requires File::Which		1.09
requires Try::Tiny          0.11

test_requires Test::More	  		0.98
test_requires Test::Pod				1.45
test_requires Test::Pod::Coverage	1.08

no_index directory	qw{ t xt eg share inc privinc }
homepage		http://padre.perlide.org/trac/wiki/PadrePluginSpellCheck
bugtracker		http://padre.perlide.org/trac
repository		http://svn.perlide.org/padre/trunk/Padre-Plugin-SpellCheck/
install_share
