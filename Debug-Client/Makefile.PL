# use 5.008005;
use strict;
use inc::Module::Install 1.00;

# Define metadata
name 'Debug-Client';
license 'perl';
author 'Gabor Szabo <gabor@szabgab.com>';
author 'Breno G. de Oliveira <garu at cpan.org>';
author 'Kevin Dawson <bowtie@cpan.org>';
author 'Ahmad M. Zawawi <ahmad.zawawi@gmail.com>';

perl_version '5.008';

# All from our core
all_from 'lib/Debug/Client.pm';

# required modules from CPAN
requires 'perl'             => '5.008';
requires 'Carp'             => '1.20';
requires 'IO::Socket'       => '1.31';
requires 'IO::Socket::INET' => '1.31';
requires 'PadWalker'        => '1.92';

test_requires 'Test::More'    => '0.98';
test_requires 'Test::Deep'    => '0.108';
test_requires 'File::HomeDir' => '0.98';
test_requires 'File::Temp'    => '0.20';
test_requires 'File::Spec'    => '3.2701';

# additinal
no_index 'directory' => qw{ t xt eg share inc privinc };
homepage 'http://padre.perlide.org/';
bugtracker 'http://padre.perlide.org/trac';
repository 'http://svn.perlide.org/padre/trunk/Debug-Client/';

WriteAll;
