use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Padre::Plugin::Catalyst',
    license             => 'perl',
    dist_author         => 'Breno G. de Oliveira <garu@cpan.org>',
    dist_version_from   => 'lib/Padre/Plugin/Catalyst.pm',
    dist_abstract       => 'Simple Catalyst helper interface for Padre',
    configure_requires  => { 'Padre::PluginBuilder' => 0.12, },
    build_requires => {
        'Test::More' => 0,
        'Module::Build' => 0.30,
        'Padre' => 0.43,
        'Catalyst::Devel' => 1.0,
        'Module::Pluggable::Object' => 3.9,
    },
    add_to_cleanup      => [ 'Padre-Plugin-Catalyst-*' ],
    create_makefile_pl => 'traditional',
    meta_merge     => {
        resources => {
            homepage   => 'http://padre.perlide.org/',
            repository => 'http://svn.perlide.org/padre/trunk/Padre-Plugin-Catalyst/',
        }
    },
);

$builder->create_build_script();
