use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Perl6::Refactor',
    license             => 'artistic_2',
    dist_author         => 'Ahmad M. Zawawi <ahmad.zawawi@gmail.com>',
    dist_version_from   => 'lib/Perl6/Refactor.pm',
    build_requires => {
        'Test::More' => 0,
    },
    add_to_cleanup      => [ 'Perl6-Refactor-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
