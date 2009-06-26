use inc::Module::Install 0.91;

all_from      'lib/Perl/Dist/Padre.pm';
requires      'Perl::Dist::Strawberry' => '1.11';
requires      'Perl::Dist::WiX'        => '0.185';
test_requires 'Test::More'             => '0.42';
test_requires 'LWP::Online'            => '1.07';

WriteAll;
