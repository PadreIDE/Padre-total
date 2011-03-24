package Module::Build::Scintilla;

use strict;
use warnings;
use Alien::wxWidgets;
use Module::Build;

our @ISA = qw(Module::Build);

sub ACTION_build {
	my $self = shift;
	$self->build_scintilla();
	$self->build_xs();
	$self->SUPER::ACTION_build;
}

sub process_xs_files {

	# Override Module::Build with a null implementation
	# We will be doing our own custom XS file handling
}

sub build_scintilla {
	my $self = shift;

	$self->log_info("Building Scintilla library\n");

	my @modules = (
		glob('wx-scintilla/src/scintilla/src/*.cxx'),
		'wx-scintilla/src/PlatWX.cpp',
		'wx-scintilla/src/ScintillaWX.cpp',
		'wx-scintilla/src/scintilla.cpp',
	);

	my @include_dirs = (
		'-Iwx-scintilla/include',
		'-Iwx-scintilla/src/scintilla/include',
		'-Iwx-scintilla/src/scintilla/src',
		'-Iwx-scintilla/src',
		Alien::wxWidgets->include_path
	);

	my @objects = ();
	for my $module (@modules) {
		$self->log_info("Compiling $module\n");
		my $filename = File::Basename::basename($module);
		$filename =~ s/(.c|.cpp|.cxx)$/.o/;
		my $object_name = File::Spec->catfile( File::Basename::dirname($module), "scintilladll_$filename" );
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

		$self->log_debug("$cmd\n");
		system($cmd);
		push @objects, $object_name;
	}

	my $dll = 'libwxmsw28u_scintilla.dll';
	my $lib = 'libwxmsw28u_scintilla.a';
	$self->log_info("Linking $dll\n");
	my @cmd = (
		Alien::wxWidgets->compiler,
		'-shared -fPIC -o ' . $dll,
		'-mthreads',
		join( ' ', @objects ),
		'-Wl,--out-implib=' . $lib,
		'-lgdi32',
		Alien::wxWidgets->libraries(qw(core base)),
	);
	my $cmd = join( ' ', @cmd );

	$self->log_debug("$cmd\n");
	system($cmd);
}

sub build_xs {
	my $self = shift;

	$self->log_info("Building Scintilla XS\n");

	my @cmd;
	my $cmd;

	require ExtUtils::ParseXS;
	ExtUtils::ParseXS::process_file(
		filename    => 'Scintilla.xs',
		output      => 'Scintilla.c',
		prototypes  => 0,
		linenumbers => 0,
		typemap     => [
			'C:/strawberry/perl/lib/ExtUtils/typemap',
			'wx_typemap',
			'typemap',
		],
	);

	@cmd = (
		Alien::wxWidgets->compiler,
		'-fvtable-thunks -O2 -mthreads -Os -c -o Scintilla.o',
		'-I.',
		'-Ic:/strawberry/perl/site/lib/Wx/',
		'-IC:/strawberry/perl/site/lib/Alien/wxWidgets/msw_2_8_10_uni_gcc_3_4/lib/',
		'-IC:/strawberry/perl/site/lib/Alien/wxWidgets/msw_2_8_10_uni_gcc_3_4/include/',
		'-s -O2 -DWIN32 -DHAVE_DES_FCRYPT -DUSE_SITECUSTOMIZE -DPERL_IMPLICIT_CONTEXT -DPERL_IMPLICIT_SYS',
		'-fno-strict-aliasing -mms-bitfields -DPERL_MSVCRT_READFIX -s -O2',
		'-DVERSION=\"0.01\" -DXS_VERSION=\"0.01\"',
		'-IC:/strawberry/perl/lib/CORE',
		'-DWXPL_EXT -DHAVE_W32API_H -D__WXMSW__ -D_UNICODE -DWXUSINGDLL -DNOPCH -DNO_GCC_PRAGMA',
		'Scintilla.c',
	);
	$cmd = join( ' ', @cmd );
	$self->log_info("$cmd\n");
	system($cmd);

	$self->log_info("Running Mkbootstrap for Wx::Scintilla\n");
	if ( open my $fh, '>Scintilla.bs' ) {
		chmod( 644, 'Scintilla.bs' );
	}

	require ExtUtils::Mksymlists;
	ExtUtils::Mksymlists::Mksymlists(
		'NAME'     => 'Wx::Scintilla',
		'DLBASE'   => 'Scintilla',
		'DL_FUNCS' => {},
		'FUNCLIST' => [],
		'IMPORTS'  => {},
		'DL_VARS'  => []
	);

	my $dll = 'blib/arch/auto/Wx/Scintilla/Scintilla.dll';
	File::Path::mkpath( File::Basename::dirname($dll), 0, oct(777) );

	@cmd = (
		Alien::wxWidgets->compiler,
		'-shared -s -o ' . $dll,
		'Scintilla.o',
		'C:/strawberry/perl/lib/CORE/libperl512.a',
		'C:/strawberry/perl/site/lib/Alien/wxWidgets/msw_2_8_10_uni_gcc_3_4/lib/libwxmsw28u_core.a',
		'C:/strawberry/perl/site/lib/Alien/wxWidgets/msw_2_8_10_uni_gcc_3_4/lib/libwxbase28u.a',
		'C:/strawberry/c/i686-w64-mingw32/lib/libgdi32.a',
		'libwxmsw28u_scintilla.a',
		'Scintilla.def',
	);
	$cmd = join( ' ', @cmd );
	$self->log_info("$cmd\n");
	system($cmd);

	require File::Copy;
	chmod( 755, 'blib/arch/auto/Wx/Scintilla/Scintilla.dll' );
	File::Copy::copy( 'Scintilla.bs', 'blib/arch/auto/Wx/Scintilla/Scintilla.bs' ) or die "Cannot copy Scintilla.bs\n";
	chmod( 644, 'blib/arch/auto/Wx/Scintilla/Scintilla.bs' );
}

1;
