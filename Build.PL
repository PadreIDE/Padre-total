use strict;
use warnings;

use Module::Build ();

my $builder = Module::Build->new(
    module_name          => 'Padre::Plugin::PerlTidy',
    license              => 'perl',
    dist_author          => 'Brian Cassidy',
    create_makefile_pl   => 'traditional',
    create_readme        => 1,
    recursive_test_files => 0,

    requires => {
        'perl'       => '5.008',
        'Perl::Tidy' => 0,
        'Padre'      => '0.12',
    },
    build_requires => { 'Test::More' => '0.47', },
);

$builder->create_build_script();
