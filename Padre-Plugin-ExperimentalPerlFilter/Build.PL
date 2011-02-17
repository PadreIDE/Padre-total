use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
	module_name       => 'Padre::Plugin::ExperimentalPerlFilter',
	license           => 'perl',
	dist_author       => 'Sebastian Willing <sewi@cpan.org>',
	dist_version_from => 'lib/Padre/Plugin/ExperimentalPerlFilter.pm',
	build_requires    => {
		'Test::More'  => 0,
	},
	requires => {
		'Padre'       => '0.80',
	},
	create_makefile_pl => 'traditional',
	meta_merge         => {
		resources => {
			homepage   => 'http://padre.perlide.org/',
			repository => 'http://svn.perlide.org/padre/trunk/Padre-Plugin-ExperimentalPerlFilter/',
		}
	},
);

$builder->create_build_script();
