package Module::Build::Scintilla::GTK;

use strict;
use warnings;
use Module::Build::Scintilla;
use Config;

our @ISA = qw( Module::Build::Scintilla );

sub stc_scintilla_lib {''}

sub stc_link_paths {
	my $self    = shift;
	my $libpath = $Config{libpth};
	my @paths   = split( /\s+/, $libpath );
	return '-L' . join( ' -L', @paths );
}

sub stc_scintilla_dll {
	my $self    = shift;
	my $dllname = 'libwx_gtk2';
	$dllname .= 'u' if Alien::wxWidgets->config->{unicode};
	$dllname .= 'd' if Alien::wxWidgets->config->{debug};
	$dllname .= '_scintilla-';
	my ( $major, $minor, $release ) = $self->stc_version_strings;
	$dllname .= $major . '.' . $minor . '.so';
	return $dllname;
}

sub stc_scintilla_link { $_[0]->stc_scintilla_dll; }

sub stc_build_scintilla_object {
	my ( $self, $module, $object_name, $includedirs ) = @_;

	my @cmd = (
		$self->stc_compiler,
		$self->stc_ccflags,
		$self->stc_defines,
		'-c -fPIC',
		'-o ' . $object_name,
		'-O2 ',
		'-Wall ',
		'-MT' . $object_name,
		'-MF' . $object_name . '.d',
		'-MD -MP',
		join( ' ', @$includedirs ),
		$module,
	);

	$self->_run_command( \@cmd );
}

sub stc_prebuild_check {
	my $self      = shift;
	my $ld        = Alien::wxWidgets->linker;
	my $libstring = $self->stc_extra_scintilla_libs;
	my $outfile   = 'stc_checkdepends.out';
	my $command   = qq($ld -fPIC -shared $libstring -o $outfile);
	if ( system($command) ) {
		unlink($outfile);
		print qq(Check for gtk2 development libraries failed.\n);
		print qq(Perhaps you need to install package libgtk2.0-dev or the equivalent for your system.\n);
		print qq(You can ofcourse uninstall it later after the installation is complete.\n);
		print qq(The build cannot continue.\n);
		exit(1);
	}
	unlink($outfile);
	return 1;
}

sub stc_extra_scintilla_libs {
	my $self   = shift;
	my $extras = '-lgtk-x11-2.0 -lgdk-x11-2.0 -latk-1.0 -lpangoft2-1.0 ';
	$extras .= '-lgdk_pixbuf-2.0 -lm -lpango-1.0 -lfreetype -lfontconfig -lgobject-2.0 ';
	$extras .= '-lgmodule-2.0 -lgthread-2.0 -lrt -lglib-2.0 -lpng -lz -ldl -lm ';

	#'-lgio-2.0', # does not apper to be needed and not present on some systems
	return $extras;
}

sub stc_link_scintilla_objects {
	my ( $self, $shared_lib, $objects ) = @_;

	my @cmd = (
		$self->stc_linker,
		$self->stc_ldflags,
		'-fPIC',
		' -o ' . $shared_lib,
		join( ' ', @$objects ),
		$self->stc_link_paths,
		$self->stc_extra_scintilla_libs,
		Alien::wxWidgets->libraries(qw(core base)),
		'-Wl,-soname,' . $shared_lib,
	);

	$self->_run_command( \@cmd );
}

sub stc_build_xs {
	my ($self) = @_;

	my $dist_version = $self->dist_version;

	my @cmd = (
		Alien::wxWidgets->compiler,
		'-fPIC -c -o Scintilla.o',
		'-I.',
		'-I' . $self->stc_get_wx_include_path,
		'-I' . $Config{archlib} . '/CORE',
		Alien::wxWidgets->include_path,
		Alien::wxWidgets->c_flags,
		Alien::wxWidgets->defines,
		$Config{ccflags},
		$Config{optimize},
		'-DWXPL_EXT -DVERSION=\"' . $dist_version . '\" -DXS_VERSION=\"' . $dist_version . '\"',
		'Scintilla.c',
	);

	$self->_run_command( \@cmd );
}

sub stc_link_xs {
	my ( $self, $dll ) = @_;

	my $perllib = $self->stc_find_libperl;

	my @cmd = (
		Alien::wxWidgets->linker,
		Alien::wxWidgets->link_flags,
		$Config{lddlflags},
		'-fPIC -L.',
		'-s -o ' . $dll,
		'Scintilla.o',
		$perllib,
		'blib/arch/auto/Wx/Scintilla/' . $self->stc_scintilla_link,
		Alien::wxWidgets->libraries(qw(core base)),
		$Config{perllibs},
		'-Wl,-rpath,blib/arch/auto/Wx/Scintilla',
		'-Wl,-rpath,' . File::Spec->catfile( $self->install_destination('arch'), 'auto/Wx/Scintilla' ),

	);

	$self->_run_command( \@cmd );
}

sub stc_find_libperl {
	my $self = shift;

	# this method has had fairly wide testing in another project
	my $libperlname = $Config{libperl};
	my $archlib     = $Config::Config{archlib};
	my $link        = ( $libperlname =~ /\.a$/ ) ? 'static' : 'shared';

	if ( $link eq 'static' ) {
		return '';
	}

	my $dllpath = qq($archlib/CORE/$libperlname);
	return $dllpath if -f $dllpath;
	if ( $link eq 'shared' ) {

		# search elsewhere
		my $returnpath = '';
		my @libperlpaths = split( /\s+/, $Config::Config{libpth} );
		for my $libdir (@libperlpaths) {
			if ( -f qq($libdir/$libperlname) ) {
				$returnpath = (qq($libdir/$libperlname));
				last;
			}
		}
		return $returnpath;
	} else {
		return '';
	}
}




1;
