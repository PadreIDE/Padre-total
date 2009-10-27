use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
	module_name       => 'Acme::CPANAuthors::Padre',
	license           => 'perl',
	dist_author       => 'Ahmad M. Zawawi <ahmad.zawawi@gmail.com>',
	dist_version_from => 'lib/Acme/CPANAuthors/Padre.pm',
	requires          => {
		'perl'              => '5.008',
		'Acme::CPANAuthors' => '0.09',
	},
	build_requires => {
		'Test::More' => 0,
	},
	add_to_cleanup => ['Acme-CPANAuthors-Padre-*'],
	meta_merge     => {
		resources => {
			homepage => 'http://padre.perlide.org/',
			repository =>
				'http://svn.perlide.org/padre/trunk/Padre-Plugin-Perl6/',
		}
	},
);

$builder->create_build_script();
