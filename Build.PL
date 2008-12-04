use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Padre::Plugin::Vi',
    license             => 'perl',
    dist_author         => 'Gabor Szabo <szabgab@gmail.com>',
    dist_version_from   => 'lib/Padre/Plugin/Vi.pm',
    requires => {
		'Padre' => '0.20',
		'Wx::Perl::Dialog',
    build_requires => {
        'Test::More' => 0,
    },
    add_to_cleanup      => [ 'Padre-Plugin-Vi-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
