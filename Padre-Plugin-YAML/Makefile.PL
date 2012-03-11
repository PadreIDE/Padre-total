use inc::Module::Install::DSL 1.06;

all_from      lib/Padre/Plugin/YAML.pm
requires_from lib/Padre/Document/YAML.pm

requires Padre					0.94
requires File::Spec::Functions	3.33

test_requires Test::More		0.98

no_index directory	qw{ t xt eg share inc privinc }
homepage		http://padre.perlide.org/trac/wiki/PadrePluginYAML
bugtracker		http://padre.perlide.org/trac
repository		http://svn.perlide.org/padre/trunk/Padre-Plugin-YAML/
