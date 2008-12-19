use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Padre::Plugin::CPAN',
    license             => 'perl',
    dist_author         => 'Fayland Lam <fayland@gmail.com>',
    dist_version_from   => 'lib/Padre/Plugin/CPAN.pm',
    build_requires => {
        'Test::More' => 0,
        'Padre'		 => '0.21',
        'CPAN'		 => 0,
        'File::Spec' => 0,
    },
    add_to_cleanup      => [ 'Padre-Plugin-CPAN-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
