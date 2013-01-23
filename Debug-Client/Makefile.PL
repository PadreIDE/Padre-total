use inc::Module::Install::DSL 1.06;

all_from lib/Debug/Client.pm
requires_from lib/Debug/Client.pm

requires IO::Socket::IP       0.18
requires PadWalker            1.96

test_requires File::HomeDir   1.00
test_requires Test::Class     0.38
test_requires Test::Deep      0.110
test_requires Test::More      0.98
test_requires Win32::Process  0.14 if win32

homepage                      http://padre.perlide.org/trac/wiki/Features/Perl5Debugger
bugtracker                    http://padre.perlide.org/trac/wiki/Tickets
repository                    http://svn.perlide.org/padre/trunk/Debug-Client/

no_index directory            qw{ t xt eg share inc privinc scripts }
