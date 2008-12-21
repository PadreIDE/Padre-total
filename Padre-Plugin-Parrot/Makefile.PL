use strict;
use lib 'privinc';
use inc::Module::Install;

if (not $ENV{PARROT_PATH}) {
	warn "PARROT_PATH needs to be defined\n";
	exit 0;
}

unshift @INC, (
	"$ENV{PARROT_PATH}/ext/Parrot-Embed/blib/lib",
	"$ENV{PARROT_PATH}/ext/Parrot-Embed/blib/arch",
	"$ENV{PARROT_PATH}/ext/Parrot-Embed/_build/lib",
);
require Parrot::Embed;
if ($@) {
	warn "Parrot::Embed needs to be compiled\n";
	exit 0;
}

name           'Padre-Plugin-Parrot';
license        'perl';
author         'Gabor Szabo <szabgab@gmail.com>';
all_from       'lib/Padre/Plugin/Parrot.pm';
requires       'Padre' => '0.21';
#requires => 'Parrot::Embed' => 0;
test_requires  'Test::More'              => '0.47';
no_index       'directory'               => qw{ t xt eg share inc privinc};
homepage       'http://padre.perlide.org/';
bugtracker     'http://padre.perlide.org/';
repository     'http://svn.perlide.org/padre/trunk/Padre-Plugin-Parrot';

WriteAll;
