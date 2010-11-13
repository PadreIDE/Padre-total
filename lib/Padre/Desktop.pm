package Padre::Desktop;

=pod

=head1 NAME

Padre::Desktop - Support library for Padre desktop integration

=head1 DESCRIPTION

This module provides a collection of functionality related to operating
system integration. It is intended to serve as a repository for code
relating to file extensions, desktop shortcuts, and so on.

This module is intended to be loadable without having to load the
main Padre code tree.

The workings of this module are currently undocumented.

=cut

use 5.008005;
use strict;
use warnings;
use File::Spec      ();
use Padre::Constant ();

our $VERSION = '0.74';

=pod

=head3 C<find_padre_exe>

Note: this only works under WIN32

Returns Padre's executable path and parent folder as C<(padre_exe, padre_exe_dir)>.
Returns C<undef> if not found.

=cut

sub find_padre_exe {
	return unless Padre::Constant::WXWIN32;

	my $self = shift;
	require File::Which;
	require File::Basename;
	my $padre_exe = File::Which::which('padre.exe');

	#exit if we could not find Padre's executable in PATH
	if ($padre_exe) {
		my $padre_exe_dir = File::Basename::dirname($padre_exe);
		return ( $padre_exe, $padre_exe_dir );
	} else {
		return;
	}
}

sub desktop {
	if (Padre::Constant::WXWIN32) {

		# Find Padre's executable
		my ( $padre_exe, $padre_exe_dir ) = find_padre_exe();
		return 0 unless $padre_exe;

		# Write to the registry to get the "Edit with Padre" in the
		# right-click-shell-context menu
		require Win32::TieRegistry;
		my $Registry;
		Win32::TieRegistry->import(
			TiedRef => \$Registry, Delimiter => "/", ArrayValues => 1,
		);
		$Registry->Delimiter('/');
		$Registry->{'HKEY_CLASSES_ROOT/*/shell/'} = {
			'Edit with Padre/' => {
				'Command/' => { "" => 'c:\\strawberry\\perl\\bin\\padre.exe "%1"' },
			}
			}
			or return 0;

		# Create Padre's Desktop Shortcut
		require File::HomeDir;
		my $padre_lnk = File::Spec->catfile(
			File::HomeDir->my_desktop,
			'Padre.lnk',
		);
		return 1 if -f $padre_lnk;

		# NOTE: Use Padre::Perl to make this distribution agnostic
		require Win32::Shortcut;
		my $link = Win32::Shortcut->new;
		$link->{Description}      = "Padre - The Perl IDE";
		$link->{Path}             = $padre_exe;
		$link->{WorkingDirectory} = $padre_exe_dir;
		$link->Save($padre_lnk);
		$link->Close;

		return 1;
	}

	return 0;
}

sub quicklaunch {
	if (Padre::Constant::WXWIN32) {

		# Find Padre's executable
		my ( $padre_exe, $padre_exe_dir ) = find_padre_exe();
		return 0 unless $padre_exe;

		# Code stolen and modified from File::HomeDir, which doesn't
		# natively support the non-local APPDATA folder.
		require Win32;
		my $dir = File::Spec->catdir(
			Win32::GetFolderPath( Win32::CSIDL_APPDATA(), 1 ),
			'Microsoft',
			'Internet Explorer',
			'Quick Launch',
		);
		return 0 unless $dir and -d $dir;

		# Where the file should be specifically
		my $padre_lnk = File::Spec->catfile( $dir, 'Padre.lnk' );
		return 1 if -f $padre_lnk;

		# NOTE: Use Padre::Perl to make this distribution agnostic
		require Win32::Shortcut;
		my $link = Win32::Shortcut->new;
		$link->{Path}             = $padre_exe;
		$link->{WorkingDirectory} = $padre_exe_dir;
		$link->Save($padre_lnk);
		$link->Close;

		return 1;
	}

	return 0;
}

1;

__END__

=pod

=head1 COPYRIGHT

Copyright 2008-2010 The Padre development team as listed in Padre.pm.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut

# Copyright 2008-2010 The Padre development team as listed in Padre.pm.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.
