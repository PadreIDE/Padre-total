use inc::Module::Install;

name     'Perl-Staff';
all_from 'lib/Perl/Staff.pm';
author   'Perl event staff <sewi@cpan.org>';
license  'perl';

#build_requires 'Test::More';

auto_install;

WriteAll;

