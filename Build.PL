use strict;
use warnings;
use Module::Build;

if (not $ENV{PARROT_PATH}) {
	warn "PARROT_PATH needs to be defined\n";
	exit 0;
}

unshift @INC, (
	"$ENV{PARROT_PATH}/ext/Parrot-Embed/blib/lib",
	"$ENV{PARROT_PATH}/ext/Parrot-Embed/blib/arch",
	"$ENV{PARROT_PATH}/ext/Parrot-Embed/_build/lib",
);
require Parrot::Embed;
if ($@) {
	warn "Parrot::Embed needs to be compiled\n";
	exit 0;
}

my $builder = Module::Build->new(
    module_name         => 'Padre::Plugin::Parrot',
    license             => 'perl',
    dist_author         => 'Gabor Szabo <szabgab@gmail.com>',
    dist_version_from   => 'lib/Padre/Plugin/Parrot.pm',
    build_requires => {
        'Test::More' => 0,
    },
    add_to_cleanup      => [ 'Padre-Plugin-Parrot-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
