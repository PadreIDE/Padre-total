use strict;
use warnings;

require Getopt::Long;

my ( $stc2, $help );
Getopt::Long::GetOptions(
	'stc2' => \$stc2,
	'help' => \$help
);

if ($help) {
	print <<"HELP";
Usage: perl Build.PL [--stc2]

    --stc2
        Selects scintilla 2.x for build (experimental)
HELP
	exit;
}

# Decide whether to use scintilla 1.x or 2.x
my ( $stc_builderclass, $scintilla_dir );
if ($stc2) {

	# Scintilla 2.x
	print "Selected Scintilla 2.x for build\n";
	use lib 'inc2';
	require Module::Build::Scintilla2;
	$stc_builderclass = Module::Build::Scintilla2::stc_builderclass();
	$scintilla_dir    = 'wx-scintilla2';
} else {

	# Scintilla 1.x
	print "Selected Scintilla 1.x for build.\n";
	use lib 'inc';
	require Module::Build::Scintilla;
	$stc_builderclass = Module::Build::Scintilla::stc_builderclass();
	$scintilla_dir    = 'wx-scintilla';
}

# Create build script
$stc_builderclass->new(
	module_name        => 'Wx::Scintilla',
	license            => 'perl',
	dist_author        => q{Ahmad M. Zawawi <ahmad.zawawi@gmail.com>},
	dist_version_from  => 'lib/Wx/Scintilla.pm',
	configure_requires => {
		'Module::Build' => 0.36,
	},
	build_requires => {
		'Test::More'       => 0,
		'Alien::wxWidgets' => 0,
		'Wx'               => 0,
		'ExtUtils::XSpp'   => 0,
	},
	needs_compiler => 0, # We will be doing our own XS compilation
	add_to_cleanup => [
		'Wx-Scintilla-*',
		"$scintilla_dir/src/*.o.d",
		"$scintilla_dir/src/*.o",
		"$scintilla_dir/src/*.obj",
		"$scintilla_dir/src/scintilla/src/*.o.d",
		"$scintilla_dir/src/scintilla/src/*.o",
		"$scintilla_dir/src/scintilla/src/*.obj",
		'Scintilla.c',
		'Scintilla.o',
		'Scintilla.obj',
		'Scintilla.bs',
		'Scintilla.def',
		'Scintilla_def.old',
		'blib',
		'*.dll',
		'*.pdb',
		'*.obj',
		'*.a',
		'*.so',
		'stc_checkdepends.out',
	],
	create_makefile_pl => 'small',
	meta_merge         => {
		resources => {
			homepage   => 'http://padre.perlide.org/',
			repository => 'http://svn.perlide.org/padre/trunk/Wx-Scintilla/',
		}
	},
	dist_abstract      => 'Scintilla source code editing component for wxWidgets',
	extra_linker_flags => '-lwxmsw28u_scintilla',
)->create_build_script();
