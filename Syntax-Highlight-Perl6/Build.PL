use strict;
use warnings;
use Module::Build;
require File::Spec;

my $class = Module::Build->subclass(
	class => "Module::Build::Custom",
	code => <<'SUBCLASS' );

	sub ACTION_install {
		my $self = shift;
		$self->SUPER::ACTION_install;
	}
SUBCLASS

my $builder = $class->new(
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

# Delete old STD files that were bundled before in Syntax::Highlight::Perl6
# This is needed to make sure STD r32116 does not conflict with old installation of Syntax::Highlight::Perl6
my $install_dir = $builder->install_destination('lib');
my @obsolete = (
	'DEBUG.pmc',
	'NAME.pmc',
	'LazyMap.pm',
	'Cursor.pmc',
	'STD_P5.pmc',
	'STD.pmc',
	'Stash.pmc',
	'CursorBase.pmc',
	'uniprops',
	'RE_ast.pmc',
	'Syntax/Highlight/Perl6/syml/CORE.syml',
);
foreach my $filename (@obsolete) {
	my $path = File::Spec->join($install_dir, $filename);
	if(-e $path) { 
		print "Deleting old $path\n";
		unlink $path;
	}
}

$builder->create_build_script();