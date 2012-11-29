use inc::Module::Install::DSL 1.06;

all_from lib/Padre/Plugin/Git.pm
requires_from lib/Padre/Plugin/Git.pm
requires_from lib/Padre/Plugin/Git/Output.pm
requires_from lib/Padre/Plugin/Git/Message.pm

requires CPAN::Changes 0.19
requires Carp          1.26
requires Data::Printer 0.33
requires File::Slurp   9999.19
requires File::Spec    3.33
requires File::Which   1.09
requires Padre         0.96
requires Pithub        0.01016
requires strictures    1.004004
requires Try::Tiny     0.11

test_requires Test::More  0.98

homepage    http://padre.perlide.org/trac/wiki/PadrePluginGit
bugtracker  http://padre.perlide.org/trac/wiki/Tickets
repository  http://svn.perlide.org/padre/trunk/Padre-Plugin-Git/

install_share

no_index directory  qw{ t xt eg share inc privinc }