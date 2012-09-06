use inc::Module::Install::DSL 1.06;

all_from lib/Debug/Client.pm

requires Carp                     1.20
requires IO::Socket::IP           0.17
requires strictures               1.004001
requires PadWalker                1.92
requires Term::ReadLine           1.07
requires Term::ReadLine::Perl     1.0303

test_requires File::HomeDir       0.98
test_requires File::Spec          3.33
test_requires File::Temp          0.22
test_requires Test::Deep          0.108
test_requires Test::More          0.98

homepage                          http://padre.perlide.org/trac/wiki/Features/Perl5Debugger
bugtracker                        http://padre.perlide.org/trac/wiki/Tickets
repository                        http://svn.perlide.org/padre/trunk/Debug-Client/

no_index directory                qw{ t xt eg share inc privinc }

