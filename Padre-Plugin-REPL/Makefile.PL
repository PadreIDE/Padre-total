use strict;
use warnings;
use inc::Module::Install;

name 'Padre-Plugin-REPL';
license 'perl';
author 'Ryan Niebur <ryanryan52@gmail.com>';

all_from 'lib/Padre/Plugin/REPL.pm';
requires_from 'lib/Padre/Plugin/REPL/History.pm';
requires_from 'lib/Padre/Plugin/REPL/Panel.pm';

requires 'Padre'                => '0.91';
requires 'Capture::Tiny'        => 0;
requires 'Devel::REPL'          => 0;
requires 'Devel::REPL::Script'  => 0;
requires 'Term::ReadLine::Stub' => 0;

test_requires 'Test::More' => '0.47';
no_index 'directory'       => qw{ t xt eg share inc};

homepage 'http://padre.perlide.org/';
bugtracker 'http://padre.perlide.org/';
repository 'http://svn.perlide.org/padre/trunk/Padre-Plugin-REPL';

is_padre_plugin; # authors: Install Module::Install::PadrePlugin

WriteAll;
