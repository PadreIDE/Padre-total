use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Parse::ErrorString::Perl',
    license             => 'perl',
    dist_author         => 'Petar Shangov <pshangov@yahoo.com>',
    dist_version_from   => 'lib/Parse/ErrorString/Perl.pm',
    build_requires => {
		'Test::More' => 0,
    },
	requires => {
		'Class::XSAccessor' => 0,
		'Pod::Find' => 0,
		'Pod::POM' => 0,
		'File::Spec' => 0,
		'File::Basename' => 0,
	},
    add_to_cleanup      => [ 'Parse-ErrorString-Perl-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
