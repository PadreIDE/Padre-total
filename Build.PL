use strict;
use warnings;

use Padre::PluginBuilder ();

my $builder = Padre::PluginBuilder->new(
    module_name          => 'Padre::Plugin::PerlTidy',
    license              => 'perl',
    dist_author          => 'Brian Cassidy <bricas@cpan.org>',
    create_makefile_pl   => 'traditional',
    create_readme        => 1,
    recursive_test_files => 0,

    configure_requires => {
        'Padre::PluginBuilder' => '0.12',
    },
    requires => {
        'perl'       => '5.008',
        'Perl::Tidy' => 0,
        'Padre'      => '0.12',
    },
    build_requires => { 'Test::More' => '0.47', },
);

$builder->create_build_script();

