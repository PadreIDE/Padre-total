use strict;
use lib 'privinc';
use inc::Module::Install;

# probably it is better not to require these 
# as they are only needed for some of the actions and
# we can delay their requirement to the run time

#if (not $ENV{PARROT_DIR}) {
#	warn "PARROT_DIR needs to be defined\n";
#	exit 0;
#}
#
#unshift @INC, (
#	"$ENV{PARROT_DIR}/ext/Parrot-Embed/blib/lib",
#	"$ENV{PARROT_DIR}/ext/Parrot-Embed/blib/arch",
#	"$ENV{PARROT_DIR}/ext/Parrot-Embed/_build/lib",
#);
#require Parrot::Embed;
#if ($@) {
#	warn "Parrot::Embed needs to be compiled\n";
#	exit 0;
#}

name           'Padre-Plugin-Parrot';
license        'perl';
author         'Gabor Szabo <szabgab@gmail.com>';
all_from       'lib/Padre/Plugin/Parrot.pm';
requires       'Padre' => '0.41';
#requires => 'Parrot::Embed' => 0;
test_requires  'Test::More'              => '0.47';
no_index       'directory'               => qw{ t xt eg share inc privinc};
homepage       'http://padre.perlide.org/';
bugtracker     'http://padre.perlide.org/';
repository     'http://svn.perlide.org/padre/trunk/Padre-Plugin-Parrot';

install_share;
#install_share_with_mofiles;

WriteAll;
