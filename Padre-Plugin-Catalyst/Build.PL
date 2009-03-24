use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Padre::Plugin::Catalyst',
    license             => 'perl',
    dist_author         => 'Breno G. de Oliveira <garu@cpan.org>',
    dist_version_from   => 'lib/Padre/Plugin/Catalyst.pm',
    configure_requires  => { 'Padre::PluginBuilder' => 0.12, },
    build_requires => {
        'Test::More' => 0,
        'Module::Build' => 0.30,
        'Padre' => 0.29,
        'Catalyst::Devel' => 1.0,
    },
    add_to_cleanup      => [ 'Padre-Plugin-Catalyst-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
