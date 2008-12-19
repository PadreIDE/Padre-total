use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Padre::Plugin::Encrypt',
    license             => 'perl',
    dist_author         => 'Fayland Lam <fayland@gmail.com>',
    dist_version_from   => 'lib/Padre/Plugin/Encrypt.pm',
    build_requires => {
        'Test::More' => 0,
        'Padre'		 => '0.18',
        'Padre::Wx::Dialog' => 0,
        'Crypt::CBC' => 0,
        'Crypt::Blowfish' => 0,
    },
    add_to_cleanup      => [ 'Padre-Plugin-Encrypt-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
