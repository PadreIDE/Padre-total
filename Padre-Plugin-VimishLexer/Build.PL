use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Padre::Plugin::VimishLexer',
    license             => 'perl',
    dist_author         => 'Peter Shangov <pshangov at yahoo dot com>',
    dist_version_from   => 'lib/Padre/Plugin/VimishLexer.pm',
    build_requires => {
        'Test::More' => 0,
    },
    add_to_cleanup      => [ 'Padre-Plugin-VimishLexer-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
