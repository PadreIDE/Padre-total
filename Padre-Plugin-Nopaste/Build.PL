#
# This file is part of Padre::Plugin::Nopaste.
# Copyright (c) 2009 Jerome Quelin, all rights reserved.
#
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
#

use 5.006;
use strict;
use warnings;

use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Padre::Plugin::Nopaste',
    license             => 'perl',
    dist_author         => 'Jerome Quelin <jquelin@gmail.com>',
    dist_version_from   => 'lib/Padre/Plugin/Nopaste.pm',
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        'App::Nopaste'          => 0,
        'File::Basename'        => 0,
        'File::Spec::Functions' => 0,
        'Module::Util'          => 0,
        'Padre'                 => '0.65',
        'Padre::Plugin'         => '0.65',
        'Padre::Task'           => '0.65',
        'parent'                => 0,
        'perl'                  => '5.008005', #as Padre
    },
    add_to_cleanup      => [ 'Padre-Plugin-Nopaste-*', map { ( '*/' x $_ ) . '*~' } 0..5 ],
    create_makefile_pl  => 'traditional',
    meta_merge     => {
        resources => {
            homepage   => 'http://padre.perlide.org/',
            repository => 'http://svn.perlide.org/padre/trunk/Padre-Plugin-Nopaste/',
        }
    },
);
$builder->add_build_element('png');
$builder->add_build_element('mo');
$builder->create_build_script();
