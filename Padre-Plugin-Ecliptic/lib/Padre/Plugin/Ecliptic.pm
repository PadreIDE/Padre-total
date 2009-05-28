package Padre::Plugin::Ecliptic;

use strict;
use warnings;

# exports and version
our $VERSION = '0.02';
our @EXPORT_OK = ();

use Padre::Wx ();
use Padre::Current ();
use Padre::Util   ('_T');

use base 'Padre::Plugin';

# private subroutine to return the current share directory location
sub _sharedir {
	return Cwd::realpath(File::Spec->join(File::Basename::dirname(__FILE__),'Ecliptic/share'));
}

# Returns the plugin name to Padre
sub plugin_name {
	return _T("Ecliptic");
}

# directory where to find the translations
sub plugin_locale_directory {
	return File::Spec->catdir( _sharedir(), 'locale' );
}

# This plugin is compatible with the following Padre plugin interfaces version
sub padre_interfaces {
	return 'Padre::Plugin' => 0.26,
}

# plugin icon
sub plugin_icon {
    # find resource path
    my $iconpath = File::Spec->catfile( _sharedir(), 'icons', 'ecliptic.png');

    # create and return icon
    return Wx::Bitmap->new( $iconpath, Wx::wxBITMAP_TYPE_PNG );
}

# called when the plugin is enabled
sub plugin_enable {
	return 1;
}

# called when Padre needs the plugin's menu
sub menu_plugins {
	my $self        = shift;
	my $main_window = shift;

	# Create a menu
	$self->{menu} = Wx::Menu->new;

	# Shows the "Open Resource" dialog
	Wx::Event::EVT_MENU(
		$main_window,
		$self->{menu}->Append( -1, _T("Open Resource\tCTRL-Shift-R"), ),
		sub { $self->_show_open_resource_dialog(); },
	);

	#---------
	$self->{menu}->AppendSeparator;

	# the famous about menu item...
	Wx::Event::EVT_MENU(
		$main_window,
		$self->{menu}->Append( -1, _T("About"), ),
		sub { $self->show_about },
	);

	# Return our plugin with its label
	return ( $self->plugin_name => $self->{menu} );
}

# Shows the infamous about dialog
sub show_about {
	my ($main) = @_;

	my $about = Wx::AboutDialogInfo->new;
	$about->SetName("Padre::Plugin::Ecliptic");
	$about->SetDescription(
		_T("Provides useful Eclipse-like to Padre.\n")
	);
	$about->SetVersion($VERSION);
	Wx::AboutBox( $about );
	return;
}

# Opens the resource dialog
sub _show_open_resource_dialog {
	my $self = shift;
	my $main = $self->main;

	#Check if we have an open file so we can use its directory
	my $filename = Padre::Current->filename;
	if(not $filename) {
		Wx::MessageBox(
			_T("'Open Resource' Dialog only works on named documents"),
			'Error',
			Wx::wxOK,
			$main,
		);
		
		return;
	}

	my $dir = Padre::Util::get_project_dir($filename) || File::Basename::dirname($filename);
	
	#Create and show the dialog
	require Padre::Plugin::Ecliptic::ResourceDialog;
	my $dialog  = Padre::Plugin::Ecliptic::ResourceDialog->new($self, directory => $dir);
	$dialog->ShowModal();
	
}

1;

__END__

=head1 NAME

Padre::Plugin::Ecliptic - Padre plugin for Eclipse-like features

=head1 SYNOPSIS

	1. After installation, run Padre.
	2. Make sure that it is enabled from 'Plugins\Plugin Manager".
	3. Once enabled, there should be a menu option called Plugins/Ecliptic.

=head1 DESCRIPTION

Once you enable this Plugin under Padre, you'll get a brand new menu with the following options:

=head2 'Open Resource' (Shortcut: CTRL-Shift-R)

This opens a dialog that allows you to type a search for any file that exists on the same folder as the current Padre document. 
You can use the ? to replace a single character or * to replace an entire string.

=head2 'Quick Access for menu actions'

Not implemented yet.

=head2 'About'

Shows a classic about box with this module's name and version.

=head1 AUTHOR

Ahmad M. Zawawi, C<< <ahmad.zawawi at gmail.com> >>

=head1 COPYRIGHT

Copyright 2009 Ahmad M. Zawawi, C<< <ahmad.zawawi at gmail.com> >>

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl 5 itself.
