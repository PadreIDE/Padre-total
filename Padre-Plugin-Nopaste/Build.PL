#
# This file is part of Padre::Plugin::Nopaste.
# Copyright (c) 2009 Jerome Quelin, all rights reserved.
#
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
#

use strict;
use warnings;

use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Padre::Plugin::Nopaste',
    license             => 'perl',
    dist_author         => 'Jerome Quelin <jquelin@gmail.com>',
    dist_version_from   => 'lib/Padre/Plugin/Nopaste.pm',
    build_requires => {
        'App::Nopaste'  => 0,
        'Test::More'    => 0,
        'Padre'         => '0.28',
        'Padre::Plugin' => '0.28',
        'Padre::Task'   => '0.30',
    },
    add_to_cleanup      => [ 'Padre-Plugin-Nopaste-*', map { ( '*/' x $_ ) . '*~' } 0..5 ],
    create_makefile_pl  => 'traditional',
);
$builder->add_build_element('png');

$builder->create_build_script();
