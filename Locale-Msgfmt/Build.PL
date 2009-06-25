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
        $ENV{AUTOMATED_TESTING} ? ('Locale::Maketext::Gettext' => 0) : (),
    },
    add_to_cleanup      => [ 'Locale-Msgfmt-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
