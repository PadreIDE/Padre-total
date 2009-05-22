use strict;
use warnings;

use Module::Build;

my $builder = Module::Build->new(
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
    add_to_cleanup      => [ 'Padre-Plugin-Alarm-*' ],
    create_makefile_pl => 'traditional',
    meta_merge     => {
        resources => {
            homepage   => 'http://padre.perlide.org/',
            repository => 'http://svn.perlide.org/padre/trunk/Padre-Plugin-Alarm/',
        }
    },
);

$builder->create_build_script();
