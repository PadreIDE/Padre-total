use strict;
use warnings;

use Padre::PluginBuilder ();

my $builder = Padre::PluginBuilder->new(
    module_name         => 'Padre::Plugin::AcmePlayCode',
    license             => 'perl',
    dist_author         => 'Fayland Lam <fayland@gmail.com>',
    dist_version_from   => 'lib/Padre/Plugin/AcmePlayCode.pm',
    configure_requires    => {
        'Padre::PluginBuilder'    => '0.12',
    },
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        'Acme::PlayCode' => 0,
        'Padre' => '0.26',
    },
    add_to_cleanup      => [ 'Padre-Plugin-AcmePlayCode-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
