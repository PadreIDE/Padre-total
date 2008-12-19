use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Padre::Plugin::ViewInBrowser',
    license             => 'perl',
    dist_author         => 'Fayland Lam <fayland@gmail.com>',
    dist_version_from   => 'lib/Padre/Plugin/ViewInBrowser.pm',
    build_requires => {
        'Test::More' => 0,
        'Padre'		 => '0.18',
        'Path::Class::File' => 0,
    },
    add_to_cleanup      => [ 'Padre-Plugin-ViewInBrowser-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
