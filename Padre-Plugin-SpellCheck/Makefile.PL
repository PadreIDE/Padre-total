use inc::Module::Install::DSL 1.04;

all_from      lib/Padre/Plugin/SpellCheck.pm
requires_from lib/Padre/Plugin/SpellCheck.pm
requires_from lib/Padre/Plugin/SpellCheck/Checker.pm
requires_from lib/Padre/Plugin/SpellCheck/Engine.pm
requires_from lib/Padre/Plugin/SpellCheck/Preferences.pm

requires Padre				0.93
requires Module::Util		1.07
requires Class::XSAccessor	1.13
# requires Data::Printer		0.3
requires File::Which		1.09

no_index directory	qw{ t xt eg share inc privinc }
homepage		http://padre.perlide.org/trac/wiki/PadrePluginSpellCheck
bugtracker		http://padre.perlide.org/trac
repository		http://svn.perlide.org/padre/trunk/Padre-Plugin-SpellCheck/
install_share

