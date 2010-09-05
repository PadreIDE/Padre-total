use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
	module_name       => 'Syntax::Highlight::Perl6',
	license           => 'perl',
	dist_author       => 'Ahmad M. Zawawi',
	dist_version_from => 'lib/Syntax/Highlight/Perl6.pm',
	build_requires    => {
		'Test::More'      => '0.86',
		'Test::Exception' => '0.27',
	},
	requires           => {
		'Term::ANSIColor'      => '2.00',
		'STD'                  => '32116',
	},
	add_to_cleanup     => ['Syntax-Highlight-Perl6-*'],
	meta_merge         => {
		resources => {
			repository => 'http://svn.perlide.org/padre/trunk/Syntax-Highlight-Perl6/',
		},
	},
);

$builder->add_build_element('ansi');
$builder->add_build_element('css');
$builder->add_build_element('js');
$builder->create_build_script();