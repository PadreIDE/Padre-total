package Module::Build::Scintilla;

use strict;
use warnings;
use Alien::wxWidgets;
use Module::Build;
use Config;

our @ISA = qw(Module::Build);

sub ACTION_build {
	my $self = shift;

	my $toolkit = Alien::wxWidgets->config->{toolkit};
	my $dll;
	my $lib;
	if( $toolkit eq 'msw') {
		$self->{_wx_toolkit_define} = '-D__WXMSW__';
		$self->{_wx_mthreads_define} = '-mthreads';
		$self->{_wx_msw_define} = '-DHAVE_W32API_H';
		$self->{_wx_scintilla_shared_lib} = 'libwxmsw28u_scintilla.dll';
		$self->{_wx_scintilla_lib} = 'libwxmsw28u_scintilla.a';
	} elsif( $toolkit =~ 'gtk' ) {
		$self->{_wx_toolkit_define} = '-D__WXGTK__';
		$self->{_wx_mthreads_define} = '';
		$self->{_wx_msw_define} = '';
		$self->{_wx_scintilla_shared_lib} = 'libwxgtk28u_scintilla.so';
		$self->{_wx_scintilla_lib} = 'libwxgtk28u_scintilla.a';
	} else {
		die "Unhandled Alien::wxWidgets->config->{toolkit} '$toolkit'. Please report this to the author\n";
	}
	
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
		my $filename = File::Basename::basename($module);
		$filename =~ s/(.c|.cpp|.cxx)$/.o/;
		my $object_name = File::Spec->catfile( File::Basename::dirname($module), "scintilladll_$filename" );
		unless(-f $object_name) {
			my @cmd = (
				Alien::wxWidgets->compiler,
				'-c',
				'-o ' . $object_name,
				'-O2 ' . $self->{_wx_mthreads_define} . ' ' . $self->{_wx_msw_define} . ' -D_UNICODE',
				'-Wall ',
				'-DWXBUILDING ' . $self->{_wx_toolkit_define} . ' -D__WX__ -DSCI_LEXER ',
				'-D__WX__ -DSCI_LEXER -DLINK_LEXERS -DWXUSINGDLL -DWXMAKINGDLL_STC',
				'-Wno-ctor-dtor-privacy',
				'-MT' . $object_name,
				'-MF' . $object_name . '.d',
				'-MD -MP',
				join( ' ', @include_dirs ),
				$module,
			);

			my $cmd = join( ' ', @cmd ) ;
			$self->log_info("$cmd\n");
			system($cmd);
		}
		push @objects, $object_name;
	}

	# Create distribution share directory
	my $dist_dir = 'blib/arch/auto/Wx/Scintilla/';
	File::Path::mkpath( $dist_dir, 0, oct(777) );

	my $shared_lib = File::Spec->catfile($dist_dir . $self->{_wx_scintilla_shared_lib});
	$self->log_info("Linking $shared_lib\n");
	my @cmd = (
		Alien::wxWidgets->compiler,
		'-shared -fPIC -o ' . $shared_lib,
		$self->{_wx_mthreads_define},
		join( ' ', @objects ),
		'-Wl,--out-implib=' . $self->{_wx_scintilla_lib},
		'-lgdi32',
		Alien::wxWidgets->libraries(qw(core base)),
	);
	my $cmd = join( ' ', @cmd );

	$self->log_info("$cmd\n");
	system($cmd);
}

sub build_xs {
	my $self = shift;

	$self->log_info("Building Scintilla XS\n");

	my @cmd;
	my $cmd;

	my $perl_lib = $Config{privlibexp};
	$perl_lib =~ s/\\/\//g;
	my $perl_site_lib = $Config{sitelibexp};
	$perl_site_lib =~ s/\\/\//g;

	require ExtUtils::ParseXS;
	ExtUtils::ParseXS::process_file(
		filename    => 'Scintilla.xs',
		output      => 'Scintilla.c',
		prototypes  => 0,
		linenumbers => 0,
		typemap     => [
			File::Spec->catfile( $perl_lib, 'ExtUtils/typemap' ),
			'wx_typemap',
			'typemap',
		],
	);

	@cmd = (
		Alien::wxWidgets->compiler,
		Alien::wxWidgets->c_flags . ' -c -o Scintilla.o',
		'-I.',
		'-I' . File::Spec->catfile( $perl_site_lib, 'Wx' ),
		Alien::wxWidgets->include_path,
		'-s -O2 -DWIN32 -DHAVE_DES_FCRYPT -DUSE_SITECUSTOMIZE -DPERL_IMPLICIT_CONTEXT -DPERL_IMPLICIT_SYS',
		'-fno-strict-aliasing -mms-bitfields -DPERL_MSVCRT_READFIX -s -O2',
		'-DVERSION=\"0.01\" -DXS_VERSION=\"0.01\"',
		'-I' . File::Spec->catfile( $perl_lib, 'CORE' ),
		'-DWXPL_EXT -DHAVE_W32API_H ' . $self->{_wx_toolkit_define} . ' -D_UNICODE -DWXUSINGDLL -DNOPCH -DNO_GCC_PRAGMA',
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
	@cmd = (
		Alien::wxWidgets->compiler,
		'-shared -s -o ' . $dll,
		'Scintilla.o',
		File::Spec->catfile( $perl_lib, 'CORE/' . $Config{libperl} ),
		Alien::wxWidgets->libraries(qw(core base)) . ' -lgdi32',
		$self->{_wx_scintilla_lib},
		'Scintilla.def',
	);
	$cmd = join( ' ', @cmd );
	$self->log_info("$cmd\n");
	system($cmd);

	require File::Copy;
	chmod( 755, $dll );
	File::Copy::copy( 'Scintilla.bs', 'blib/arch/auto/Wx/Scintilla/Scintilla.bs' ) or die "Cannot copy Scintilla.bs\n";
	chmod( 644, 'blib/arch/auto/Wx/Scintilla/Scintilla.bs' );
}

1;
