use strict;
use warnings;

use lib 'inc';
use Module::Build::Scintilla ();

my $builder = Module::Build::Scintilla->new(
	module_name        => 'Wx::Scintilla',
	license            => 'perl',
	dist_author        => q{Ahmad M. Zawawi <ahmad.zawawi@gmail.com>},
	dist_version_from  => 'lib/Wx/Scintilla.pm',
	configure_requires => {
		'Module::Build' => 0.36,
	},
	build_requires => {
		'Test::More'       => 0,
		'File::ShareDir'   => 0,
		'Alien::wxWidgets' => 0,
		'Wx'               => 0,
		'ExtUtils::XSpp'   => 0,
	},
	needs_compiler => 0, # We will be doing our own XS compilation
	add_to_cleanup => [
		'Wx-Scintilla-*',
		'wx-scintilla/src/*.o.d',
		'wx-scintilla/src/*.o',
		'wx-scintilla/src/scintilla/src/*.o.d',
		'wx-scintilla/src/scintilla/src/*.o',
		'Scintilla.c',
		'Scintilla.o',
		'Scintilla.bs',
		'Scintilla.def',
		'Scintilla_def.old',
		'blib',
		'*.dll',
		'*.a',
		'*.so'
	],
	meta_merge => {
		resources => {
			homepage   => 'http://padre.perlide.org/',
			repository => 'http://svn.perlide.org/padre/trunk/Wx-Scintilla/',
		}
	},
	dist_abstract => 'Fresh Perl wxWidgets XS bindings for Scintilla editor component',
);

$builder->create_build_script();
