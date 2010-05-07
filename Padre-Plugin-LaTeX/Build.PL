use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Padre::Plugin::LaTeX',
    license             => 'perl',
    dist_author         => 'Zeno Gantner <zeno.gantner@gmail.com>',
    dist_version_from   => 'lib/Padre/Plugin/LaTeX.pm',
    build_requires => {
        'Test::More'  => 0,
    },
    requires => {
        'Padre'       => '0.60',
    },
    add_to_cleanup      => [ 'Padre-Plugin-LaTeX-*' ],
    create_makefile_pl  => 'traditional',
    meta_merge     => {
        resources => {
            homepage   => 'http://padre.perlide.org/',
            repository => 'http://svn.perlide.org/padre/trunk/Padre-Plugin-LaTeX/',
        }
    },
);

$builder->create_build_script();
