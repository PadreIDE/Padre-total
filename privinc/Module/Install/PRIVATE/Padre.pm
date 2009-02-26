package Module::Install::PRIVATE::Padre;

use 5.008;
use strict;
use warnings;
use Module::Install::Base;

use FindBin    ();
use File::Find ();

our $VERSION = '0.26';
our @ISA     = qw{Module::Install::Base};

sub setup_padre {
	my $self      = shift;
	my $inc_class = join( '::', @{ $self->_top }{ qw(prefix name) } );
	my $class     = __PACKAGE__;

	$self->postamble(<<"END_MAKEFILE");
# --- Padre section:

exe :: all
\t\$(NOECHO) \$(PERL) -Iprivinc "-M$inc_class" -e "make_exe()"

ppm :: ppd all
\t\$(NOECHO) tar czf Padre.tar.gz blib/

END_MAKEFILE


}

sub check_wx_version {
	# Can we find Wx.pm
	my $wxfile = _module_file('Wx');
	my $wxpath = _file_path($wxfile);
	unless ( $wxpath ) {
		# Wx.pm is not installed.
		# Allow EU:MM to do it's thing as normal
		return;
	}
	my $wx_pm = _path_version($wxpath);
	print "Found Wx.pm     $wx_pm\n";

	# Do we have the alien package
	eval {
		require Alien::wxWidgets;
		Alien::wxWidgets->import;
	};
	if ( $@ ) {
		# If we don't have the alien package,
		# we should just pass through to EU:MM
		return;
	}

	# Find the wxWidgets version from the alien
	my $widgets = Alien::wxWidgets->version;
	unless ( $widgets ) {
		nono("Alien::wxWidgets was unable to determine the wxWidgets version");
	}
	my $widgets_human = $widgets;
	$widgets_human =~ s/^(\d\.\d\d\d)(\d\d\d)$/$1.$2/;
	$widgets_human =~ s/0//g;
	print "Found wxWidgets $widgets_human\n";
	unless ( $widgets >= 2.008008 ) {
		nono("Padre needs at least version 2.8.8 of wxWidgets. You have wxWidgets $widgets_human");
	}

	# this part still needs the DISPLAY 
	# so check only if there is one
	if ( $ENV{DISPLAY} or $^O =~ /win32/i ) {
		eval {
			require Wx;
			Wx->import;
		};
		if ($@) {
			# If we don't have the Wx installed,
			# we should just pass through to EU:MM
			return;
		}
		unless ( Wx::wxUNICODE() ) {
			nono("Padre needs wxWidgest to be compile with Unicode support (--enable-unicode)");
		}
	}

	return;
}

sub nono {
	my $msg = shift;
	print STDERR "$msg\n";
	exit(0);
}

sub make_exe {
	my $self = shift;

	# temporary tool to create executable using PAR
	eval "use Module::ScanDeps 0.88; 1;" or die $@;

	my @libs    = get_libs();
	my @modules = get_modules();
	my $exe	 = $^O =~ /win32/i ? 'padre.exe' : 'padre';
	if ( -e $exe ) {
		unlink $exe or die "Cannot remove '$exe' $!";
	}
	my @cmd	= ( 'pp', '-o', $exe, qw{ -I lib script/padre } );
	push @cmd, @modules;
	push @cmd, @libs;
	if ( $^O =~ /win32/i ) {
		push @cmd, '-M', 'Tie::Hash::NamedCapture';
	}

	print join( ' ', @cmd ) . "\n";
	system(@cmd);

	return;
}

sub get_libs {
	# Run-time "use" the Alien module
	require Alien::wxWidgets;
	Alien::wxWidgets->import;

	# Extract the settings we need from the Alient
	my $prefix = Alien::wxWidgets->prefix;
	my %libs   = map { ($_, 0) } Alien::wxWidgets->shared_libraries(
		qw(stc xrc html adv core base) 
	);

	require File::Find;
	File::Find::find(
		sub {
			if ( exists $libs{$_} ) {
				$libs{$_} = $File::Find::name;
			}
		},
		$prefix
	);

	my @missing = grep { ! $libs{$_} } keys %libs;
	foreach ( @missing ) {
		warn("Could not find shared library on disk for $_");
	}

	return map { ('-l', $_) } values %libs;
}

sub get_modules {
	my @modules;
	my @files;
	open(my $fh, '<', 'MANIFEST') or
		die("Do you need to run 'make manifest'? Could not open MANIFEST for reading: $!");
	while ( my $line = <$fh> ) {
		chomp $line;
		if ( $line =~ m{^lib/.*\.pm$} ) {
			$line = substr($line, 4, -3);
			$line =~ s{/}{::}g;
			push @modules, $line;
		}
		if ( $line =~ m{^lib/.*\.pod$} ) {
			push @files, $line;
		}
		if ( $line =~ m{^share/} ) {
			(my $newpath = $line) =~ s{^share}{lib/auto/share/dist/Padre};
			push @files, "$line;$newpath";
		}
	}

	my @args;
	push @args, "-M", $_ for @modules;
	push @args, "-a", $_ for @files;
	return @args;
}

# To prevent EU:MM loading modules, we hijack %INC and then set $VERSION
# into all of the packages so that EU:MM still gets the versions it wants.
sub trick_eumm {
	my $self     = shift;
	my @requires = map { $_ ? @$_ : () } (
		$self->configure_requires,
		$self->build_requires,
		$self->test_requires,
		$self->requires,
	);
	foreach my $module ( map { $_->[0] } @requires ) {
		# If the module is already loaded leave it alone
		my $file = _module_file($module);
		next if $INC{$file};

		# What version of the module is installed
		my $found = _file_path($file);
		unless ( defined $found ) {
			# Leave it to EU:MM to not find as well
			next;
		}

		# Parse out the version for the currently installed version
		my $version = _path_version($found);

		# Make the module look like it is loaded,
		# and set the version to match the one on disk.
		$INC{$file} = __PACKAGE__;
		no strict 'refs';
		*{"${module}::VERSION"} = sub { $version };
	}
	return 1;
}

sub _module_file {
	my $module = shift;
	$module =~ s/::/\//g;
	$module .= '.pm';
	return $module;
}

sub _file_path {
	my $file  = shift;
	my @found = grep { -f $_ } map { "$_/$file" } @INC;
	return $found[0];
}

sub _path_version {
	require ExtUtils::MM_Unix;
	ExtUtils::MM_Unix->parse_version($_[0]);
}

1;
