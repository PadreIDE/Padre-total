use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Locale::Msgfmt',
    license             => 'perl',
    dist_author         => 'Ryan Niebur <ryanryan52@gmail.com>',
    dist_version_from   => 'lib/Locale/Msgfmt.pm',
    build_requires => {
        'Test::More' => 0,
        'Locale::Maketext::Gettext' => 1.28,
    },
    add_to_cleanup      => [ 'Locale-Msgfmt-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
