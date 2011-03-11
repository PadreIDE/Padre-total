use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Wx::STC',
    license             => 'perl',
    dist_author         => q{Ahmad M. Zawawi <ahmad.zawawi@gmail.com>},
    dist_version_from   => 'lib/Wx/STC.pm',
    build_requires => {
        'Test::More' => 0,
    },
    add_to_cleanup      => [ 'Wx-STC-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
