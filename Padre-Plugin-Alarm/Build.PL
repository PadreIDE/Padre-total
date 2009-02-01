use strict;
use warnings;

use Padre::PluginBuilder ();

my $builder = Padre::PluginBuilder->new(
    module_name         => 'Padre::Plugin::Alarm',
    license             => 'perl',
    dist_author         => 'Fayland Lam <fayland@gmail.com>',
    dist_version_from   => 'lib/Padre/Plugin/Alarm.pm',
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        'Padre::Wx::Dialog' => 0,
        'Padre' 	 => '0.26',
        'Audio::Beep' => 0,
    },
    configure_requires => {
      'Padre::PluginBuilder' => '0.12',
    },
    add_to_cleanup      => [ 'Padre-Plugin-Alarm-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
