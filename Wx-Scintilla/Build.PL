use strict;
use warnings;

use Module::Build ();
use Alien::wxWidgets;

# Subclass Module::Build to compile Scintilla first at build time
my $class = Module::Build->subclass(
	class => "Module::Build::Custom",
	code  => <<'SUBCLASS' );

sub ACTION_build {
	my $self = shift;
	$self->build_scintilla();
	$self->SUPER::ACTION_build;
}

sub build_scintilla {
	my $self = shift;

	use Alien::wxWidgets;
	$self->log_info("Compiling Scintilla\n");

	my @modules = (
		glob('wx-scintilla\src\stc\scintilla\src\*.cxx'),
		'wx-scintilla\src\stc\PlatWX.cpp',
		'wx-scintilla\src\stc\ScintillaWX.cpp',
		'wx-scintilla\src\stc\stc.cpp',
	);

	my @include_dirs = (
		'-Iwx-scintilla\include',
		'-Iwx-scintilla\src\stc\scintilla\include',
		'-Iwx-scintilla\src\stc\scintilla\src',
		'-Iwx-scintilla\src\stc',
		Alien::wxWidgets->include_path
	);

	my @objects = ();
	for my $module (@modules) {
		$self->log_info("Compiling $module");
		my $filename = File::Basename::basename($module);
		$filename =~ s/(.c|.cpp|.cxx)$/.o/;
		my $object_name = File::Spec->catfile( File::Basename::dirname($module), "stcdll_$filename" );
		my @cmd = (
			Alien::wxWidgets->compiler,
			'-c',
			'-o ' . $object_name,
			'-O2 -mthreads -DHAVE_W32API_H -D__WXMSW__ -D_UNICODE',
			'-Wall ',
			'-DWXBUILDING -D__WXMSW__ -D__WX__ -DSCI_LEXER -DLINK_LEXERS',
			'-D__WX__ -DSCI_LEXER -DLINK_LEXERS -DWXUSINGDLL -DWXMAKINGDLL_STC',
			'-Wno-ctor-dtor-privacy',
			'-MT' . $object_name,
			'-MF' . $object_name . '.d',
			'-MD -MP',
			join( ' ', @include_dirs ),
			$module,
		);	
		my $cmd = join( ' ', @cmd );

		$self->log_debug($cmd);
		system($cmd);
		push @objects, $object_name;
	}

	my $dll = 'wxmsw28u_stc_gcc_custom.dll';
	$self->log_info("Linking $dll");
	my @cmd = (
		Alien::wxWidgets->compiler,
		'-shared -fPIC -o ' . $dll,
		'-mthreads',
		join( ' ', @objects ),
		'-lgdi32',
		Alien::wxWidgets->libraries(qw(core base)),
	);
	my $cmd = join( ' ', @cmd );

	$self->log_debug($cmd);
	system($cmd);
}

SUBCLASS

my $include_path = Alien::wxWidgets->include_path;
$include_path =~ s/\-I//g;
my @include_paths = split( /\s/, $include_path );

my $defines = Alien::wxWidgets->defines;
$defines =~ s/-D//g;
my @defines = split( /\s/, $defines );

my $builder = $class->new(
	module_name       => 'Wx::Scintilla',
	license           => 'perl',
	dist_author       => q{Ahmad M. Zawawi <ahmad.zawawi@gmail.com>},
	dist_version_from => 'lib/Wx/Scintilla.pm',
	build_requires    => {
		'Test::More'       => 0,
		'Alien::wxWidgets' => 0,
		'Wx'               => 0,
		'ExtUtils::XSpp'   => 0,
	},
	include_dirs => [
		'.',
		'wx-scintilla\include',
		'wx-scintilla\src\stc\scintilla\include',
		'wx-scintilla\src\stc\scintilla\src',
		'C:\strawberry\perl\site\lib\Wx',
		@include_paths
	],
	extra_compiler_flags => \@defines,
	xs_files             => {
		'Scintilla.xs' => 'lib/Wx/Scintilla.xs',
	},
	add_to_cleanup     => ['Wx-Scintilla-*'],
	create_makefile_pl => 'traditional',
	meta_merge         => {
		resources => {
			homepage   => 'http://padre.perlide.org/',
			repository => 'http://svn.perlide.org/padre/trunk/Wx-Scintilla/',
		}
	},
);

$builder->create_build_script();
