use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Padre::Plugin::LineFilter',
    license             => 'perl',
    dist_author         => 'Keedi Kim <keedi@perl.kr>',
    dist_version_from   => 'lib/Padre/Plugin/LineFilter.pm',
    requires => {
        'Test::More' => 0,
        'version'    => 0,
    },
    add_to_cleanup      => [ 'Padre-Plugin-LineFilter-*' ],
    meta_merge     => {
        resources => {
            homepage   => 'http://padre.perlide.org/',
            repository => 'http://svn.perlide.org/padre/trunk/Padre-Plugin-LineFilter/',
        }
    },
);

$builder->create_build_script();
