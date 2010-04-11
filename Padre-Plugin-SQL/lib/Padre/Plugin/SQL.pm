package Padre::Plugin::SQL;

use strict;
use warnings;
use 5.008;

# package exports and version
our $VERSION = '0.01';

# module imports
use Padre::Wx ();
use Padre::Util   ('_T');


use Padre::Plugin::SQL::DBConnection;

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
	return 'Padre::Plugin' => 0.59,
}


sub plugin_enable {

	my $self = shift;
	
	require Padre::Plugin::SQL::MessagePanel;
	$self->{msg_panel} = Padre::Plugin::SQL::MessagePanel->new($self);
	Padre::Current->main->bottom->hide($self->{msg_panel});
	#$self->{msg_panel}->show;
	
	require Padre::Plugin::SQL::ResultsPanel;
	$self->{results_panel} = Padre::Plugin::SQL::ResultsPanel->new($self);
	Padre::Current->main->bottom->hide($self->{reults_panel});
	
}

sub plugin_disable {
	
	my $self = shift;


	$self->{connection}->disconnect;
	
	# remove the SQL panels from Padre.
	#$self->{results_panel}->hide;
	#$self->{msg_panel}->hide;
	
	Padre::Current->main->bottom->hide($self->{msg_panel});	
	Padre::Current->main->bottom->hide($self->{results_panel});	
	require Class::Unload;
	Class::Unload->unload('Padre::Plugin::SQL::MessagePanel');
	Class::Unload->unload('Padre::Plugin::SQL::ResultsPanel');
	Class::Unload->unload('Padre::Plugin::SQL');
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

	Wx::Event::EVT_MENU(
		$main_window,
		$self->{menu}->Append( -1, _T("Execute Query"), ),
		sub { $self->run_query(); },
	);
	
	Wx::Event::EVT_MENU(
		$main_window,
		$self->{menu}->Append( -1, _T("Disconnect from Database"), ),
		sub { $self->disconnectDB(); },
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

	$self->{conn_details} = $dialog->get_connection();
	
	$dialog->Destroy();
	
	print "conn_details = " . $self->{conn_details} . "\n";
	
	
	$self->connectDB();
	return;
}




sub connectDB {
	my( $self ) = @_;
	print "connectDB()\n";
	print "details: \n";
	foreach my $detail ( keys ( %{ $self->{conn_details} } ) ){
		print "$detail: " . $self->{conn_details}->{$detail} . "\n";
		
	}
	
	if( ! defined $self->{connection} ) {
		$self->{connection} = Padre::Plugin::SQL::DBConnection->new($self->{conn_details});
	}
	
	
	if( $self->{connection}->is_connected ) {
		$self->{connection}->disconnect();
		$self->{connection}->connect($self->{conn_details});
		
		
	}
	else {
	
		my $connection = Padre::Plugin::SQL::DBConnection->new($self->{conn_details});
		if( $connection->err ) {
			
			print "Error: " . $connection->errstr;
			
		}
		$self->{connection} = undef;
		
		my $main = Padre::Current->main;
		$main->error("Error: " . $connection->errstr);
		return;
	}
	
	# if it all goes well 
	# We need to open a document window that 'belongs' to
	# the plugin
	if( defined( $self->{connection} ) ) {
		my $main = Padre->ide->wx->main;
		$main->new_document_from_string( "select *\nfrom ", 'text/x-sql' );
		
		Padre::Current->main->bottom->show($self->{results_panel});
		Padre::Current->main->bottom->show($self->{msg_panel});	
		
	}
	
}


sub run_query {
	my $self = shift;
	my $query = shift;
	
	if( ! defined($query) ) {
		my $editor = Padre::Current->editor;
		#my $editor = $current->editor;
		my $string  = $editor->GetSelectedText();
		$query = $string;
		print "Selected Text: $query\n";
	}
	if( ! defined($query) || $query eq '' ) {
		$self->{msg_panel}->update_messages("No string highlighted for query.");
		return;
	}
	
	$self->{connection}->run_query($query);
	#my $sth = $self->{dbh}->prepare($query);
	# handle error from DB here
	if( $self->{connection}->err ) {
		$self->{msg_panel}->update_messages($self->{connection}->errstr);
		
		return;
	}
	
	
	#$sth->execute();
	# handle error
	if( $self->{connection}->err ) {
		$self->{msg_panel}->update_messages($self->{connection}->errstr);
		return;
	}
	#my @results;
	#$results[0] = $sth->{NAME};
	#$results[1] = $sth->fetchall_arrayref();
	
	my $results = $self->{connection}->get_results;
	
 	my $msg = "Returned: " . scalar( @{ $results->[1] } ) . " rows.\n";
 	print $msg;
 	
 	$self->{msg_panel}->update_messages($msg);
	$self->{results_panel}->update_grid($results);
	
}

sub disconnectDB {
	my ( $self, $connDetails ) = @_;
	print "disconnectDB()\n";
	if( defined $self->{connection} ) {
		$self->{connection}->disconnect();
	}
	else {
		print "No DB connection defined yet\n";
	}
	#$self->{msg_panel}->hide;
	#$self->{results_panel}->hide;
	Padre::Current->main->bottom->hide($self->{msg_panel});	
	Padre::Current->main->bottom->hide($self->{results_panel});	
	#$self->{msg_panel}->Destroy;
	#$self->{results_panel}->Destroy;
	
	#$self->{msg_panel} = undef;
	#$self->{results_panel} = undef;
	
}


sub msg_panel { return shift->{msg_panel}; }
sub result_panel{ return shift->{result_panel}; }
1;

__END__

=head1 NAME

Padre::Plugin::SQL - Padre plugin that provides database access

=head1 SYNOPSIS

	1. After installation, run Padre.
	2. Make sure that it is enabled from 'Plugins/Plugin Manager".
	3. Once enabled, there should be a menu option called Plugins/SQL.

=head1 DESCRIPTION

Once you enable this Plugin under Padre, you'll get a brand new menu with the 
following options:

=head2 'Setup Connection to Database'

This opens a dialog that allows you to select one of the already configured
database connections or setup a new one.


=head2 'Execute Query'

Takes what ever text is highlighted in the editor and passes that
to the db handle to first 'prepare'.  If it parses ok by the database
it then executes the query.

=head2  Disconnect

Disconnects from the database.

=head2 'About'

Shows a classic about box with this module's name and version.


=head1 AUTHOR

Original Author: 0.01
	Gabor Szabo, C<< <szabgab at gmail.com> >>

Follow up work: 0.02
	More workable Main Dialog
	Actually connects to a database
	Actually queries a database
	Added SQL Messages and Database Results as output panels
	
	Peter Lavender, C<< <peter.lavender at gmail.com> >>


=head1 COPYRIGHT

Copyright 2009 Gabor Szabo, C<< <szabgab at gmail.com> >>

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl 5 itself.

=cut

# Copyright 2008-2010 The Padre development team as listed in Padre.pm.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.