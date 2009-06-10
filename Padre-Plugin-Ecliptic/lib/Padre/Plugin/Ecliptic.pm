package Padre::Plugin::Ecliptic;

use strict;
use warnings;

# package exports and version
our $VERSION = '0.08';
our @EXPORT_OK = ();

# module imports
use Padre::Wx ();
use Padre::Util   ('_T');

# is a subclass of Padre::Plugin
use base 'Padre::Plugin';

#
# private subroutine to return the current share directory location
#
sub _sharedir {
	return Cwd::realpath(File::Spec->join(File::Basename::dirname(__FILE__),
		'Ecliptic/share'));
}

#
# Returns the plugin name to Padre
#
sub plugin_name {
	return _T("Ecliptic");
}

#
# Directory where to find the translations
#
sub plugin_locale_directory {
	return File::Spec->catdir( _sharedir(), 'locale' );
}

#
# This plugin is compatible with the following Padre plugin interfaces version
#
sub padre_interfaces {
	return 'Padre::Plugin' => 0.26,
}

#
# plugin icon
#
sub plugin_icon {
    # find resource path
    my $iconpath = File::Spec->catfile( _sharedir(), 'icons', 'ecliptic.png');

    # create and return icon
    return Wx::Bitmap->new( $iconpath, Wx::wxBITMAP_TYPE_PNG );
}

#
# called when Padre needs the plugin's menu
#
sub menu_plugins {
	my $self        = shift;
	my $main_window = shift;

	# Create a menu
	$self->{menu} = Wx::Menu->new;

	# Shows the "Open Resource" dialog
	Wx::Event::EVT_MENU(
		$main_window,
		$self->{menu}->Append( -1, _T("Open Resource\tCtrl-Shift-R"), ),
		sub { $self->_show_open_resource_dialog(); },
	);

	# Shows the "List Key Bindings" dialog
	Wx::Event::EVT_MENU(
		$main_window,
		$self->{menu}->Append( -1, _T("List Key Bindings\tCtrl-Shift-L"), ),
		sub { $self->_show_list_key_bindings_dialog(); },
	);
	
	# Shows the "Quick Menu Access" dialog
	Wx::Event::EVT_MENU(
		$main_window,
		$self->{menu}->Append( -1, _T("Quick Menu Access\tCtrl-3"), ),
		sub { $self->_show_quick_menu_access_dialog(); },
	);
	
	# Shows the "Quick Outline Access" dialog
	Wx::Event::EVT_MENU(
		$main_window,
		$self->{menu}->Append( -1, _T("Quick Outline Access\tCtrl-4"), ),
		sub { $self->_show_quick_outline_access_dialog(); },
	);

	# Shows the "Quick Module Access" dialog
	Wx::Event::EVT_MENU(
		$main_window,
		$self->{menu}->Append( -1, _T("Quick Module Access\tCtrl-5"), ),
		sub { $self->_show_quick_module_access_dialog(); },
	);

	# "Open in Explorer" action
	Wx::Event::EVT_MENU(
		$main_window,
		$self->{menu}->Append( -1, _T("Open in Explorer\tCtrl-6"), ),
		sub { $self->_open_in_explorer(); },
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

#
# Shows the nice about dialog
#
sub show_about {
	my ($main) = @_;

	my $about = Wx::AboutDialogInfo->new;
	$about->SetName("Padre::Plugin::Ecliptic");
	$about->SetDescription(
		_T("Provides Eclipse-like useful features to Padre.\n")
	);
	$about->SetVersion($VERSION);
	Wx::AboutBox( $about );
	
	return;
}

#
# Opens the "Open Resource" dialog
#
sub _show_open_resource_dialog {
	my $self = shift;

	#Create and show the dialog
	require Padre::Plugin::Ecliptic::OpenResourceDialog;
	my $dialog  = Padre::Plugin::Ecliptic::OpenResourceDialog->new($self);
	$dialog->ShowModal();

	return;
}

#
# Opens the "List Key Bindings" dialog
#
sub _show_list_key_bindings_dialog {
	my $self = shift;

	#Create and show the dialog
	require Padre::Plugin::Ecliptic::ListKeyBindingsDialog;
	my $dialog  = Padre::Plugin::Ecliptic::ListKeyBindingsDialog->new($self);
	$dialog->ShowModal();

	return;
}

#
# Opens the "Quick Menu Access" dialog
#
sub _show_quick_menu_access_dialog {
	my $self = shift;

	#Create and show the dialog
	require Padre::Plugin::Ecliptic::QuickMenuAccessDialog;
	my $dialog  = Padre::Plugin::Ecliptic::QuickMenuAccessDialog->new($self);
	$dialog->ShowModal();

	return;
}

#
# Opens the "Quick Outline Access" dialog
#
sub _show_quick_outline_access_dialog {
	my $self = shift;

	#Create and show the dialog
	require Padre::Plugin::Ecliptic::QuickOutlineAccessDialog;
	my $dialog  = Padre::Plugin::Ecliptic::QuickOutlineAccessDialog->new($self);
	$dialog->ShowModal();

	return;
}

#
# Opens the "Quick Module Access" dialog
#
sub _show_quick_module_access_dialog {
	my $self = shift;

	#Create and show the dialog
	require Padre::Plugin::Ecliptic::QuickModuleAccessDialog;
	my $dialog  = Padre::Plugin::Ecliptic::QuickModuleAccessDialog->new($self);
	$dialog->ShowModal();

	return;
}

#
# For the current "saved" Padre document,
# On win32, selects it in Windows Explorer
# On linux, opens the containing folder for it
#
sub _open_in_explorer {
	my $self = shift;

	#XXX- implement "Open in explorer"
	# In windows,
	# exec: 
	# explorer.exe /select,"c:\tools\putty.exe"

	# In KDE, search for defined $ENV{KDEDIR}
	# kfmclient exec $FILE_PATH
	# http://developer.kde.org/documentation/other/kfmclient.html

	# How about using FindBin to check whether kfmclient or nautilus is installed and favour KDE in that situation.
 
	# In Gnome, search for defined $ENV{GNOME_DESKTOP_SESSION_ID}
	# nautilus --nodesktop --browser $FILE_PATH	
	
	return;
}

1;

__END__

=head1 NAME

Padre::Plugin::Ecliptic - Padre plugin that provides Eclipse-like useful features

=head1 SYNOPSIS

	1. After installation, run Padre.
	2. Make sure that it is enabled from 'Plugins\Plugin Manager".
	3. Once enabled, there should be a menu option called Plugins/Ecliptic.

=head1 DESCRIPTION

Once you enable this Plugin under Padre, you'll get a brand new menu with the 
following options:

=head2 'Open Resource' (Shortcut: Ctrl-Shift-R)

This opens a nice dialog that allows you to find any file that exists 
in the current document or working directory. You can use ? to replace 
a single character or * to replace an entire string. The matched files list 
are sorted alphabetically and you can select one or more files to be opened in Padre
when you press the OK button.

You can simply ignore CVS, .svn and .git folders using a simple checkbox 
(enhancement over Eclipse).

=head2 List Key Bindings (Shortcut: Ctrl-Shift-L)

This opens a dialog with a yellow list of current Padre actions/shortcuts. When you hit the OK 
button, the selected Padre action will be performed.

=head2 Quick Menu Access (Shortcut: Ctrl-3)

This opens a dialog where you can search for menu labels. When you hit the OK 
button, the menu item will be selected.

=head2 Quick Outline Access (Shortcut: Ctrl-4)

This opens a dialog where you can search for outline tree. When you hit the OK 
button, the outline element in the outline tree will be selected.

=head2 Quick Module Access (Shortcut: Ctrl-5)

This opens a dialog where you can search for a CPAN module. When you hit the OK 
button, the selected module will be displayed in Padre's POD browser.

=head2 Open in Explorer (Shortcut: Ctrl-6)

For the current saved Padre document, open the platform's file manager and tries to select it if possible.
On win32, opens the containing folder and selects the file in explorer. On *inux KDE/GNOME, 
opens the containing folder for it.

=head2 'About'

Shows a classic about box with this module's name and version.

=head1 Why the name Ecliptic?

I wanted a simple plugin name for including Eclipse-related killer features into 
Padre. So i came up with Ecliptic and it turned out to be the orbit which the 
Sun takes. And i love it!

=head1 AUTHOR

Ahmad M. Zawawi, C<< <ahmad.zawawi at gmail.com> >>

=head1 COPYRIGHT

Copyright 2009 Ahmad M. Zawawi, C<< <ahmad.zawawi at gmail.com> >>

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl 5 itself.
