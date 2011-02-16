use inc::Module::Install 1.00;

name           'Padre-Plugin-SVN';
all_from       'lib/Padre/Plugin/SVN.pm';
author         'Gabor Szabo <szabgab@gmail.com>';
license        'perl';
requires       'Padre'      => '0.81';
requires       'SVN::Class' => '0.15'; # For --file support
build_requires 'Test::More';

# Extras needed for building Padre plugins
is_padre_plugin;

WriteAll;
