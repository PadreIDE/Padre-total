use inc::Module::Install::DSL 1.04;

all_from	lib/Debug/Client.pm

requires Carp					1.23
requires IO::Socket				1.31
requires IO::Socket::INET		1.31
requires PadWalker				1.92
requires Term::ReadLine			1.07
requires Term::ReadLine::Perl	1.0303

test_requires Test::More		0.98
test_requires Test::Deep		0.108
test_requires Test::Class		0.36
test_requires File::HomeDir		0.98
test_requires File::Temp		0.22
test_requires File::Spec		3.33

no_index directory	qw{ t xt eg share inc privinc }
homepage			http://padre.perlide.org/
bugtracker			http://padre.perlide.org/trac
repository			http://svn.perlide.org/padre/trunk/Debug-Client/

WriteAll
