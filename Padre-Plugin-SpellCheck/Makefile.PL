use inc::Module::Install::DSL 1.06;

all_from      lib/Padre/Plugin/SpellCheck.pm
requires_from lib/Padre/Plugin/SpellCheck.pm
requires_from lib/Padre/Plugin/SpellCheck/Checker.pm
requires_from lib/Padre/Plugin/SpellCheck/Engine.pm
requires_from lib/Padre/Plugin/SpellCheck/Preferences.pm

requires Class::Accessor 0.34
requires File::Which     1.09
requires Moo             1.000007
requires Padre           0.98
requires Text::Aspell    0.09 if win32
requires Text::Hunspell  2.07 if !win32
requires Try::Tiny       0.12
requires constant        1.27
requires parent          0.225

test_requires Test::More 0.98

no_index directory qw{ t xt eg share inc privinc }

homepage    http://padre.perlide.org/trac/wiki/PadrePluginSpellCheck
bugtracker  http://padre.perlide.org/trac
repository  http://svn.perlide.org/padre/trunk/Padre-Plugin-SpellCheck/

install_share
