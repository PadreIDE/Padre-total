#
# This file is part of Padre::Plugin::Autoformat.
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
    module_name         => 'Padre::Plugin::Autoformat',
    license             => 'perl',
    dist_author         => 'Jerome Quelin <jquelin@gmail.com>',
    dist_version_from   => 'lib/Padre/Plugin/Autoformat.pm',
    build_requires => {
        'Test::More'       => 0,
        'Text::Autoformat' => 0,
        'Padre'            => '0.30',
    },
    requires => {
        'File::Basename'        => 0,
        'File::Spec::Functions' => 0,
        'Module::Util'          => 0,
    },
    add_to_cleanup      => [ 'Padre-Plugin-Autoformat-*', map { ( '*/' x $_ ) . '*~' } 0..5 ],
    create_makefile_pl  => 'traditional',
);
$builder->add_build_element('png');

$builder->create_build_script();
