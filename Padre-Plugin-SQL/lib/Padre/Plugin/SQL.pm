package Padre::Plugin::SQL;

use strict;
use warnings;
use 5.008;

# package exports and version
our $VERSION = '0.01';

# module imports
use Padre::Wx ();
use Padre::Util   ('_T');

# is a subclass of Padre::Plugin
use base 'Padre::Plugin';

#
# Returns the plugin name to Padre
#
sub plugin_name {
	return _T("SQL");
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
#sub plugin_icon {
#    my $self = shift;
#    # find resource path
#    my $iconpath = File::Spec->catfile( $self->plugin_directory_share, 'icons', 'sql.png');
#
#    # create and return icon
#    return Wx::Bitmap->new( $iconpath, Wx::wxBITMAP_TYPE_PNG );
#}
#
#
# called when Padre needs the plugin's menu
#
sub menu_plugins {
	my $self        = shift;
	my $main_window = shift;

	# Create a menu
	$self->{menu} = Wx::Menu->new;

	Wx::Event::EVT_MENU(
		$main_window,
		$self->{menu}->Append( -1, _T("Setup Connection to Database"), ),
		sub { $self->setup_connection(); },
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
	$about->SetName(__PACKAGE__);
	$about->SetDescription(
		_T("Provides database access to Padre.\n")
	);
	$about->SetVersion($VERSION);
	Wx::AboutBox( $about );
	
	return;
}

#
# Opens the "Setup Connection" dialog
#
sub setup_connection {
	my $self = shift;

	#Create and show the dialog
	require Padre::Plugin::SQL::SetupConnectionsDialog;
	my $dialog  = Padre::Plugin::SQL::SetupConnectionsDialog->new($self);
	$dialog->ShowModal();

	return;
}


1;

__END__

=head1 NAME

Padre::Plugin::SQL - Padre plugin that provides database access

=head1 SYNOPSIS

	1. After installation, run Padre.
	2. Make sure that it is enabled from 'Plugins\Plugin Manager".
	3. Once enabled, there should be a menu option called Plugins/SQL.

=head1 DESCRIPTION

Once you enable this Plugin under Padre, you'll get a brand new menu with the 
following options:

=head2 'Setup Connection to Database'

This opens a dialog that allows you to select one of the already configured
database connections or setup a new one.


=head2 'About'

Shows a classic about box with this module's name and version.


=head1 AUTHOR

Gabor Szabo, C<< <szabgab at gmail.com> >>

=head1 COPYRIGHT

Copyright 2009 Gabor Szabo, C<< <szabgab at gmail.com> >>

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl 5 itself.

=cut

