use inc::Module::Install 0.91;

all_from      'lib/Perl/Dist/Padre.pm';
requires      'Perl::Dist::Strawberry' => '1.1114';
requires      'Perl::Dist::WiX'        => '0.192';
test_requires 'Test::More'             => '0.42';
test_requires 'LWP::Online'            => '1.07';
resources     'repository'             => 'https://svn.perlide.org/padre/trunk/Perl-Dist-Padre';
resources     'bugtracker'             => 'http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Perl-Dist-Padre';
resources     'homepage'               => 'http://padre.perlide.org/';
resources     'IRC'                    => 'irc://irc.perl.org/#padre';
resources     'Web2IRC'                => 'http://widget.mibbit.com/?server=irc.perl.org&channel=%23padre';

WriteAll;
