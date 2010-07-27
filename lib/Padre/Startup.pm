package Padre::Startup;

=pod

=head1 NAME

Padre::Startup::Config - Padre start-up related configuration settings

=head1 DESCRIPTION

Padre stores host-related data in a combination of an easily transportable
YAML file for personal settings and a powerful and robust SQLite-based
configuration database for host settings and state data.

Unfortunately, fully loading and validating these configurations can be
relatively expensive and may take some time. A limited number of these
settings need to be available extremely early in the Padre bootstrapping
process.

The F<startup.yml> file is automatically written at the same time as the
regular configuration files, and is read without validating during early start-up.

L<Padre::Startup::Config> is a small convenience module for reading and
writing the F<startup.yml> file.

=head1 FUNCTIONS

=cut

use 5.008005;
use strict;
use warnings;
use Padre::Constant ();

our $VERSION = '0.68';

my $SPLASH = undef;

use constant AllowSetForeground => <<'END_API';
BOOL AllowSetForegroundWindow(
	DWORD dwProcessId
);
END_API





#####################################################################
# Main Startup Procedure

# Runs the (as light as possible) startup process for Padre.
# Returns true if we should continue with the startup.
# Returns false if we should abort the startup and exit.
sub startup {

	# Start with the default settings
	my %setting = (
		main_singleinstance      => Padre::Constant::DEFAULT_SINGLEINSTANCE,
		main_singleinstance_port => Padre::Constant::DEFAULT_SINGLEINSTANCE_PORT,
		startup_splash           => 1,
		threads                  => 1,
	);

	# Load and overlay the startup.yml file
	if ( -f Padre::Constant::CONFIG_STARTUP ) {
		%setting = ( %setting, startup_config() );
	}

	# Attempt to connect to the single instance server
	if ( $setting{main_singleinstance} ) {

		# This blocks for about 1 second
		require IO::Socket;
		my $socket = IO::Socket::INET->new(
			PeerAddr => '127.0.0.1',
			PeerPort => $setting{main_singleinstance_port},
			Proto    => 'tcp',
			Type     => IO::Socket::SOCK_STREAM(),
		);
		if ($socket) {
			my $pid = '';
			my $read = $socket->sysread( $pid, 10 );
			if ( defined $read and $read == 10 ) {

				# Got the single instance PID
				$pid =~ s/\s+\s//;
				if (Padre::Constant::WIN32) {
					require Win32::API;
					Win32::API->new(
						user32 => AllowSetForeground,
					)->Call($pid);
				}
			}
			foreach my $file (@ARGV) {
				require File::Spec;
				my $path = File::Spec->rel2abs($file);
				$socket->print("open $path\n");
			}
			$socket->print("focus\n");
			$socket->close;
			return 0;
		}
	}

	# NOTE: Replace the following with if ( 0 ) will disable the
	# slave master quick-spawn optimisation.

	# Second-generation version of the threading optimisation.
	# This one is much safer because we start with zero existing tasks
	# and no expectation of existing load behaviour.
	if ( $setting{threads} ) {
		require Padre::TaskThread;
		Padre::TaskThread->master;
	}

	# Show the splash image now we are starting a new instance
	# Shows Padre's splash screen if this is the first time
	# It is saved as BMP as it seems (from wxWidgets documentation)
	# that it is the most portable format (and we don't need to
	# call Wx::InitAllImageHeaders() or whatever)
	if ( $setting{startup_splash} ) {

		# Don't show the splash screen during testing otherwise
		# it will spoil the flashy surprise when they upgrade.
		unless ( $ENV{HARNESS_ACTIVE} or $ENV{PADRE_NOSPLASH} ) {
			require File::Spec;

			# Find the base share directory
			my $share = undef;
			if ( $ENV{PADRE_DEV} ) {
				require FindBin;
				no warnings;
				$share = File::Spec->catdir(
					$FindBin::Bin,
					File::Spec->updir,
					'share',
				);
			} else {
				require File::ShareDir;
				$share = File::ShareDir::dist_dir('Padre');
			}

			# Locate the splash image without resorting to the use
			# of any Padre::Util functions whatsoever.
			my $splash = File::Spec->catfile( $share, 'padre-splash-ccnc.bmp' );

			# Use CCNC-licensed version if it exists and fallback
			# to the boring splash so that we can bundle it in
			# Debian without their packaging team needing to apply
			# any custom patches to the code, just delete the file.
			unless ( -f $splash ) {
				$splash = File::Spec->catfile(
					$share, 'padre-splash.bmp',
				);
			}

			# Load just enough modules to get Wx bootstrapped
			# to the point it can show the splash screen.
			require Wx;
			$SPLASH = Wx::SplashScreen->new(
				Wx::Bitmap->new(
					$splash,
					Wx::wxBITMAP_TYPE_BMP()
				),
				Wx::wxSPLASH_CENTRE_ON_SCREEN() | Wx::wxSPLASH_TIMEOUT(),
				3500, undef, -1
			);
		}
	}

	return 1;
}

sub startup_config {
	open( my $FILE, '<', Padre::Constant::CONFIG_STARTUP ) or return ();
	my @buffer = <$FILE>;
	close $FILE or return ();
	chomp @buffer;
	return @buffer;
}

# Destroy the splash screen if it exists
sub destroy_splash {
	if ($SPLASH) {
		$SPLASH->Destroy;
		$SPLASH = 1;
	}
}

1;

# Copyright 2008-2010 The Padre development team as listed in Padre.pm.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.
