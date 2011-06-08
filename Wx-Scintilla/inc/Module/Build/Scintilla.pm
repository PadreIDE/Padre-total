package Module::Build::Scintilla;

use strict;
use warnings;
use Module::Build;

our @ISA = qw(Module::Build);

sub ACTION_build {
	my $self = shift;

	require Alien::wxWidgets;
	Alien::wxWidgets->import;

	my $toolkit = Alien::wxWidgets->config->{toolkit};
	if ( $toolkit eq 'msw' ) {
		$self->{_wx_toolkit}              = $toolkit;
		$self->{_wx_toolkit_define}       = '-D__WXMSW__';
		$self->{_wx_mthreads_define}      = '-mthreads';
		$self->{_wx_msw_define}           = '-DHAVE_W32API_H';
		$self->{_wx_scintilla_shared_lib} = 'libwx_msw28u_scintilla.dll';
		$self->{_wx_scintilla_lib}        = 'libwx_msw28u_scintilla.a';
	} elsif ( $toolkit =~ 'gtk' ) {
		$self->{_wx_toolkit}              = $toolkit;
		$self->{_wx_toolkit_define}       = '-D__WXGTK__';
		$self->{_wx_mthreads_define}      = '';
		$self->{_wx_msw_define}           = '';
		$self->{_wx_scintilla_shared_lib} = 'libwx_gtk28u_scintilla.so';
		$self->{_wx_scintilla_lib}        = '';
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

#
# Joins the list of commands to form a command, executes it a C<system> call
# and handles CTRL-C and bad exit codes
#
sub _run_command {
	my $self = shift;
	my $cmds = shift;

	my $cmd = join( ' ', @$cmds );
	$self->log_info("$cmd\n");
	my $rc = system($cmd);
	die "Failed with exit code $rc" if $rc != 0;
	die "Ctrl-C interrupted command\n" if $rc & 127;
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
		unless ( -f $object_name ) {
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

			$self->_run_command( \@cmd );
		}
		push @objects, $object_name;
	}

	# Create distribution share directory
	my $dist_dir = 'blib/arch/auto/Wx/Scintilla';
	File::Path::mkpath( $dist_dir, 0, oct(777) );

	my $shared_lib = File::Spec->catfile( $dist_dir, $self->{_wx_scintilla_shared_lib} );

	$self->log_info("Linking $shared_lib\n");
	my @cmd;

	if ( $self->{_wx_toolkit} eq 'msw' ) {
		@cmd = (
			Alien::wxWidgets->compiler,
			'-shared -fPIC -o ' . $shared_lib,
			$self->{_wx_mthreads_define},
			join( ' ', @objects ),
			'-Wl,--out-implib=' . $self->{_wx_scintilla_lib},
			'-lgdi32',
			Alien::wxWidgets->libraries(qw(core base)),
		);
	} elsif ( $self->{_wx_toolkit} =~ 'gtk' ) {
		@cmd = (
			Alien::wxWidgets->compiler,
			'-shared -fPIC',
			'-Wl,-soname,' . $self->{_wx_scintilla_shared_lib},
			'-o ' . $shared_lib,
			join( ' ', @objects ),
			'-pthread -L/usr/lib/i386-linux-gnu -lgtk-x11-2.0 -lgdk-x11-2.0',
			'-latk-1.0 -lgio-2.0 -lpangoft2-1.0 -lgdk_pixbuf-2.0 -lm -lpango-1.0 -lfreetype -lfontconfig -lgobject-2.0',
			'-lgmodule-2.0 -lgthread-2.0 -lrt -lglib-2.0 -lpng -lz -ldl -lm',
		);
	}

	$self->_run_command( \@cmd );
}

sub build_xs {
	my $self = shift;

	$self->log_info("Building Scintilla XS\n");

	my @cmd;
	my $cmd;

	my $perl_lib = $self->config('privlibexp');
	$perl_lib =~ s/\\/\//g;
	my $perl_arch_lib = $self->config('archlib');
	$perl_arch_lib =~ s/\\/\//g;
	my $perl_site_arch = $self->config('sitearch');
	$perl_site_arch =~ s/\\/\//g;

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

	my $dist_version = $self->dist_version;
	my $toolkit      = $self->{_wx_toolkit};
	if ( $toolkit eq 'msw' ) {

		# win32
		@cmd = (
			Alien::wxWidgets->compiler,
			Alien::wxWidgets->c_flags . ' -c -o Scintilla.o',
			'-I.',
			'-I' . File::Spec->catfile( $perl_site_arch, 'Wx' ),
			Alien::wxWidgets->include_path,
			'-s -O2 -DWIN32 -DHAVE_DES_FCRYPT -DUSE_SITECUSTOMIZE -DPERL_IMPLICIT_CONTEXT -DPERL_IMPLICIT_SYS',
			'-fno-strict-aliasing -mms-bitfields -DPERL_MSVCRT_READFIX -s -O2',
			'-DVERSION=\"' . $dist_version . '\" -DXS_VERSION=\"' . $dist_version . '\"',
			'-I' . File::Spec->catfile( $perl_arch_lib, 'CORE' ),
			'-DWXPL_EXT -DHAVE_W32API_H '
				. $self->{_wx_toolkit_define}
				. ' -D_UNICODE -DWXUSINGDLL -DNOPCH -DNO_GCC_PRAGMA',
			'Scintilla.c',
		);
	} else {

		# GTK
		@cmd = (
			Alien::wxWidgets->compiler,
			Alien::wxWidgets->c_flags . ' -c -o Scintilla.o',
			'-I.',
			'-I' . File::Spec->catfile( $perl_site_arch, 'Wx' ),
			Alien::wxWidgets->include_path,
			'-D_REENTRANT -D_GNU_SOURCE -fno-strict-aliasing -pipe -fstack-protector -D_FILE_OFFSET_BITS=64 -O2 -D_LARGEFILE_SOURCE',
			'-I/usr/local/include',
			'-DVERSION=\"' . $dist_version . '\" -DXS_VERSION=\"' . $dist_version . '\"',
			'-I' . File::Spec->catfile( $perl_arch_lib, 'CORE' ),
			'-DWXPL_EXT '
				. $self->{_wx_toolkit_define}
				. ' -D_LARGE_FILES',
			'Scintilla.c',
		);

	}
	$self->_run_command( \@cmd );

	if ( open my $fh, '>Scintilla.bs' ) {
		close $fh;
	}


	if ( $toolkit eq 'msw' ) {
		$self->log_info("Running Mkbootstrap for Wx::Scintilla\n");

		require ExtUtils::Mksymlists;
		ExtUtils::Mksymlists::Mksymlists(
			'NAME'     => 'Wx::Scintilla',
			'DLBASE'   => 'Scintilla',
			'DL_FUNCS' => {},
			'FUNCLIST' => [],
			'IMPORTS'  => {},
			'DL_VARS'  => []
		);
	}

	my $dll = File::Spec->catfile(
		'blib/arch/auto/Wx/Scintilla',
		$self->{_wx_toolkit} eq 'msw' ? 'Scintilla.dll' : 'Scintilla.so'
	);
	if ( $toolkit eq 'msw' ) {
		@cmd = (
			Alien::wxWidgets->compiler,
			'-shared -s -o ' . $dll,
			'Scintilla.o',
			File::Spec->catfile( $perl_arch_lib, 'CORE/' . $self->config('libperl') ),
			Alien::wxWidgets->libraries(qw(core base)) . ' -lgdi32',
			$self->{_wx_scintilla_lib},
			'Scintilla.def',
		);
	} else {

		#GTK
		my $shared_lib = File::Spec->catfile( 'blib/arch/auto/Wx/Scintilla/', $self->{_wx_scintilla_shared_lib} );

		@cmd = (
			Alien::wxWidgets->compiler,
			'-shared -s -o ' . $dll,
			'Scintilla.o',
			'-L/usr/local/lib',
			'-fstack-protector',
			File::Spec->catfile( $perl_arch_lib, 'CORE/' . $self->config('libperl') ),
			Alien::wxWidgets->libraries(qw(core base)),
			$shared_lib,
			'-Wl,-rpath,blib/arch/auto/Wx/Scintilla',
			'-Wl,-rpath,' . File::Spec->catfile( $self->install_destination('arch'), 'auto/Wx/Scintilla' ),
		);
	}
	$self->_run_command( \@cmd );

	chmod( 0755, $dll );


	require File::Copy;
	unlink('blib/arch/auto/Wx/Scintilla/Scintilla.bs');
	File::Copy::copy( 'Scintilla.bs', 'blib/arch/auto/Wx/Scintilla/Scintilla.bs' ) or die "Cannot copy Scintilla.bs\n";
	chmod( 0644, 'blib/arch/auto/Wx/Scintilla/Scintilla.bs' );
}

1;
