use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Padre::Plugin::Mojolicious',
    license             => 'perl',
    dist_author         => 'Breno G. de Oliveira <garu@cpan.org>',
    dist_version_from   => 'lib/Padre/Plugin/Mojolicious.pm',
    dist_abstract       => 'Simple Mojolicious helper interface for Padre',
    configure_requires  => { 'Padre::PluginBuilder' => 0.12, },
    build_requires => {
        'Test::More' => 0,
        'Module::Build' => 0.30,
        'File::Basename' => 0,
        'Padre' => 0.29,
        'Mojo' => 0.9,
        'Module::Pluggable::Object' => 3.9,
    },
    add_to_cleanup      => [ 'Padre-Plugin-Mojolicious-*' ],
    create_makefile_pl => 'traditional',
    meta_merge     => {
        resources => {
            homepage   => 'http://padre.perlide.org/',
            repository => 'http://svn.perlide.org/padre/trunk/Padre-Plugin-Mojolicious/',
        }
    },
);

$builder->create_build_script();
