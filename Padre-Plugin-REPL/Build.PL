use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Padre::Plugin::REPL',
    license             => 'perl',
    dist_author         => 'Ryan Niebur <ryanryan52@gmail.com>',
    dist_version_from   => 'lib/Padre/Plugin/REPL.pm',
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        'Padre' => 0,
        'Capture::Tiny' => 0,
        'Devel::REPL' => 0,
        'Class::Unload' => 0
    },
    add_to_cleanup      => [ 'Padre-Plugin-REPL-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
