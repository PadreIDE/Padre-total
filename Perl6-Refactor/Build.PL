use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
	module_name         => 'Perl6::Refactor',
	license           => 'perl',
	dist_author         => 'Ahmad M. Zawawi <ahmad.zawawi@gmail.com>',
	dist_version_from   => 'lib/Perl6/Refactor.pm',
	build_requires => {
		'Test::More'               => '0.86',
		'Syntax::Highlight::Perl6' => '0.64',
	},
	add_to_cleanup      => [ 'Perl6-Refactor-*' ],
	create_makefile_pl => 'traditional',
	meta_merge         => {
		resources => {
			homepage => 'http://padre.perlide.org/',
			repository =>
				'http://svn.perlide.org/padre/trunk/Perl6-Refactor/',
		}
	},
);

$builder->create_build_script();
