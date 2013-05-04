use inc::Module::Install::DSL 1.06;

all_from lib/Debug/Client.pm
requires_from lib/Debug/Client.pm

requires Carp                 1.26
requires IO::Socket::IP       0.2
requires PadWalker            1.96
requires Term::ReadKey        2.30
requires Term::ReadLine       1.10
requires Term::ReadLine::Perl 1.0303
requires constant             1.27

test_requires Exporter       5.68
test_requires File::HomeDir  1
test_requires File::Spec     3.4
test_requires File::Temp     0.2301
test_requires Test::Class    0.39
test_requires Test::Deep     0.11
test_requires Test::More     0.98
test_requires Win32          0.47 if win32
test_requires Win32::Process 0.14 if win32
test_requires parent         0.225
test_requires version        0.9902

recommends Test::Pod           1.46
recommends Test::Pod::Coverage 1.08

homepage                      http://padre.perlide.org/trac/wiki/Features/Perl5Debugger
bugtracker                    http://padre.perlide.org/trac/wiki/Tickets
repository                    http://svn.perlide.org/padre/trunk/Debug-Client/

no_index directory            qw{ t xt eg share inc privinc scripts }
