use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Padre::Plugin::XML',
    license             => 'perl',
    dist_author         => 'Fayland Lam <fayland@gmail.com>',
    dist_version_from   => 'lib/Padre/Plugin/XML.pm',
    build_requires => {
        'Test::More'  => 0,
        'Padre'       => '0.21',
        'XML::Tidy'   => 0,
        'XML::LibXML' => '1.67',
    },
    add_to_cleanup      => [ 'Padre-Plugin-XML-*' ],
    create_makefile_pl  => 'traditional',
);

$builder->create_build_script();
