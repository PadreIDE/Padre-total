use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Padre::Plugin::CommandLine',
    license             => 'perl',
    dist_author         => 'Gabor Szabo <szabgab@gmail.com>',
    dist_version_from   => 'lib/Padre/Plugin/CommandLine.pm',
    requires => {
		'Padre'             => '0.16',
		'Wx::Perl::Dialog'  => '0.02',
    },
    build_requires => {
        'Test::More' => 0,
    },
    add_to_cleanup      => [ 'Padre-Plugin-CommandLine-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
