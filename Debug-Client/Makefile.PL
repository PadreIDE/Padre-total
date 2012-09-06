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
test_requires Test::Pod           1.45
test_requires Test::Pod::Coverage 1.08

homepage                          http://padre.perlide.org/trac/wiki/Features/Perl5Debugger
bugtracker                        http://padre.perlide.org/trac/wiki/Tickets
repository                        http://svn.perlide.org/padre/trunk/Debug-Client/

no_index directory                qw{ t xt eg share inc privinc }


__END__
1	use inc::Module::Install::DSL 1.06;
2	
3	all_from    lib/Debug/Client.pm
4	
5	requires Carp                   1.20
6	requires IO::Socket::IP         0.17
7	requires PadWalker              1.92
8	requires Term::ReadLine         1.07
9	requires Term::ReadLine::Perl   1.0303
10	
11	test_requires File::HomeDir         0.98
12	test_requires File::Spec            3.33
13	test_requires File::Temp            0.22
14	test_requires Test::Class           0.36
15	test_requires Test::Deep            0.108
16	test_requires Test::More            0.98
17	test_requires Test::Pod             1.45
18	test_requires Test::Pod::Coverage   1.08
19	
20	no_index directory  qw{ t xt eg share inc privinc }
21	homepage            http://padre.perlide.org/trac/wiki/Features/Perl5Debugger
22	bugtracker          http://padre.perlide.org/trac/wiki/Tickets
23	repository          http://svn.perlide.org/padre/trunk/Debug-Client/
24	
25	WriteAll