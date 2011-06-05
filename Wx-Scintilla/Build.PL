use strict;
use warnings;

# We do not support other than Win32 for Wx::Scintilla for now
# So please die and play nice with CPAN testers :)
die "OS unsupported\n" if $^O ne 'MSWin32';

use lib 'inc';
use Module::Build::Scintilla ();
use Alien::wxWidgets;

my $include_path = Alien::wxWidgets->include_path;
$include_path =~ s/\-I//g;
my @include_paths = split( /\s/, $include_path );

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
	include_dirs   => [
		'.',
		'wx-scintilla/include',
		'wx-scintilla/src/scintilla/include',
		'wx-scintilla/src/scintilla/src',
		'C:/strawberry/perl/site/lib/Wx',
		@include_paths
	],
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
	create_makefile_pl => 'traditional',
	meta_merge         => {
		resources => {
			homepage   => 'http://padre.perlide.org/',
			repository => 'http://svn.perlide.org/padre/trunk/Wx-Scintilla/',
		}
	},
	verbose => 1,
);

$builder->create_build_script();
