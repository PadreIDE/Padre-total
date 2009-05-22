use strict;
use warnings;

use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Padre::Plugin::AcmePlayCode',
    license             => 'perl',
    dist_author         => 'Fayland Lam <fayland@gmail.com>',
    dist_version_from   => 'lib/Padre/Plugin/AcmePlayCode.pm',
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        'Acme::PlayCode' => 0,
        'Padre' => '0.26',
    },
    add_to_cleanup      => [ 'Padre-Plugin-AcmePlayCode-*' ],
    create_makefile_pl => 'traditional',
    meta_merge     => {
        resources => {
            homepage   => 'http://padre.perlide.org/',
            repository => 'http://svn.perlide.org/padre/trunk/Padre-Plugin-AcmePlayCode/',
        }
    },
);

$builder->create_build_script();
