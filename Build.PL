#
# This file is part of Padre::Plugin::SpellCheck.
# Copyright (c) 2009 Jerome Quelin, all rights reserved.
#
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
#

use strict;
use warnings;

use Module::Build;

my $class = Module::Build->subclass(
    class => "Module::Build::Custom",
    code => <<'SUBCLASS' );

sub ACTION_build {
    my $self = shift;

    my $msgfmt = $^O =~ /(linux|bsd)/
        ? `which msgfmt`
        : "c:/Program Files/GnuWin32/bin/msgfmt.exe";
    chomp $msgfmt;
    if ( $msgfmt && -e $msgfmt ) {
        my @pofiles = glob "lib/Padre/Plugin/SpellCheck/share/locale/*.po";
        foreach my $pof ( @pofiles ) {
                my $mof = $pof;
                $mof =~ s/\.po$/.mo/;
                $self->do_system( "$msgfmt -o $mof $pof" );
        }
    }
    $self->SUPER::ACTION_build;
}

SUBCLASS


my $builder = $class->new(
    module_name         => 'Padre::Plugin::SpellCheck',
    license             => 'perl',
    dist_author         => 'Jerome Quelin <jquelin@gmail.com>',
    dist_version_from   => 'lib/Padre/Plugin/SpellCheck.pm',
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        'File::Basename'        => 0,
        'File::Spec::Functions' => 0,
        'Module::Util'          => 0,
        'Padre'                 => '0.26',
        'Text::Aspell'          => 0,
        'Class::XSAccessor'     => 0,
    },
    add_to_cleanup      => [ 'Padre-Plugin-SpellCheck-*',
        map { ( '*/' x $_ ) . '*~' } 0..5 ],
    create_makefile_pl  => 'traditional',
);
$builder->add_build_element('mo');
$builder->add_build_element('png');

$builder->create_build_script();
