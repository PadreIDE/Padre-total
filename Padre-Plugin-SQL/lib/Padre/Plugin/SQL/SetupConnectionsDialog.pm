package Padre::Plugin::SQL::SetupConnectionsDialog;

use warnings;
use strict;

# package exports and version
our $VERSION = '0.02';

# module imports
use Padre::Wx ();
use Padre::Current ();
use Padre::Util   ('_T');

use YAML::Tiny;
use Data::Dumper;


# is a subclass of Wx::Dialog
use base 'Wx::Dialog';

# accessors
use Class::XSAccessor accessors => {
	_sizer             => '_sizer',              # window sizer
};


# we could make it dynamic in terms of the DBD's availalbe
# however there are a few DBD's installed that require 
# special handling, so for now we'll handle them this way in 
# terms of the ones we support.
my %dbTypes = (
		'Postgres' 	=> { port => 5432 },
		'MySQL'		=> { port => 3306 },
	);

# config file name
my $config_file = 'db_connections.yml';

# -- constructor
sub new {
	my ($class, $plugin, %opt) = @_;

	# we need the share directory
	my $share_dir = $plugin->plugin_directory_share;
	
	# this doesn't work when running dev.pl -a
	if( ! defined( $share_dir) || $share_dir eq '' ) {
		
		$share_dir = '/tmp';
		
	}
	
	my $db_connections;
	my $path = File::Spec->catfile($share_dir, $config_file);	
	if( ! -e $path ) {
		#print "No config file exists\n";
		$db_connections = YAML::Tiny->new();
		
	}
	else {
		#print "Loading config file $path\n";
		$db_connections = YAML::Tiny->read($path);
		if( ! defined $db_connections ) {
			# create error dialog here.
			print "failed to read config " . YAML::Tiny->errstr . "\n";
		}
	}
	
	# create object
	my $self = $class->SUPER::new(
		Padre::Current->main,
		-1,
		_T('Setup Database connection'),
		Wx::wxDefaultPosition,
		Wx::wxDefaultSize,
		Wx::wxDEFAULT_FRAME_STYLE|Wx::wxTAB_TRAVERSAL,
	);

	$self->SetIcon( Wx::GetWxPerlIcon() );

	$self->{db_connections} = $db_connections;
	$self->{config_path}  = $path;
	
	$self->{connection_details} = undef;
	
	
	# create dialog
	$self->_create;

	return $self;
}




# -- event handler

#
# handler called when the ok button has been clicked.
# 
sub _on_ok_button_clicked {
	my ($self) = @_;

	# my $main = Padre->ide->wx->main;
	my %connection_details;
	#$connection_details{'user'} = txt
	#$self->create_connection_details;
	$self->Hide;
}

sub _on_cancel_button_clicked {
	my $self = shift;
	$self->Hide;
	#$self->Destroy;
	return undef;
}

# -- private methods

#
# create the dialog itself.
#
sub _create {
	my ($self) = @_;

	# create sizer that will host all controls
	my $sizer = Wx::BoxSizer->new( Wx::wxVERTICAL );
	$self->_sizer($sizer);

	# create the controls
	$self->_existing_db_connections;
	$self->_db_connection_list;
	$self->_setup_db_conn;
	$self->_create_buttons;

	# wrap everything in a vbox to add some padding
	$self->SetSizerAndFit($sizer);
	$sizer->SetSizeHints($self);

	# center the dialog
	$self->Centre;
}

#
# create the buttons pane.
#
sub _create_buttons {
	my ($self) = @_;
	my $sizer  = $self->_sizer;

	my $butsizer = Wx::BoxSizer->new( Wx::wxHORIZONTAL );
	my $btnCancel = Wx::Button->new($self, -1, 'Cancel');
	
	#my $okID = Wx::NewId();
	my $btnOK = Wx::Button->new($self, -1, 'OK');
	
	#my $saveID = Wx::NewId();
	my $btnSave = Wx::Button->new($self, -1,  'Save Connection');
	
	#my $delID = Wx::NewId();
	my $btnDelete = Wx::Button->new($self, -1, 'Delete Connection');
	
	
	$butsizer->Add($btnSave, 0, Wx::wxALL|Wx::wxEXPAND|Wx::wxALIGN_CENTER, 5);
	$butsizer->Add($btnDelete, 0, Wx::wxALL|Wx::wxEXPAND|Wx::wxALIGN_CENTER, 5);
	$butsizer->Add($btnOK, 0, Wx::wxALL|Wx::wxEXPAND|Wx::wxALIGN_CENTER, 5);
	$butsizer->Add($btnCancel, 0, Wx::wxALL|Wx::wxEXPAND|Wx::wxALIGN_CENTER, 5);
	
	$sizer->Add($butsizer, 0, Wx::wxALL|Wx::wxEXPAND|Wx::wxALIGN_RIGHT, 5 );
	
	Wx::Event::EVT_BUTTON(
		$self,
		$btnOK,
		sub { $_[0]->_on_ok_button_clicked; } 
	);
	Wx::Event::EVT_BUTTON(
		$self,
		$btnSave,
		sub { $_[0]->_save_config; }
	);
	Wx::Event::EVT_BUTTON(
		$self,
		$btnDelete,
		sub { $_[0]->_delete_config; }
	);
	
	Wx::Event::EVT_BUTTON(
		$self,
		$btnCancel,
		sub { $_[0]->_on_cancel_button_clicked; }
	);
	
	
}

sub _delete_config {
	my $self = shift;
	print "_delete_config\n";
	my $connname = $self->{dbConnList_combo}->GetValue();
	print "deleting: $connname\n";
	delete $self->{db_connections}->[0]->{$connname};
	my $ok = $self->{db_connections}->write( $self->{config_path} );
	
	if( ! $ok ) {
		# TODO DIALOG 
		#print "Error??? " . $self->{db_connections}->errstr . "\n";
	}
	
	$self->_reset_form();
	
	
}


sub _read_config {
	my $self = shift;

	my $ok = $self->{db_connections}->read( $self->{config_path} );
	if( ! $ok ) {
		
		print "Error??? " . $self->{db_connections}->errstr . "\n";
	}
	
}

=pod

=head2 _save_config

This checks and saves the current config details in the form

=cut

sub _save_config {
	my $self = shift;
	print "_save_config\n";
	#YAML::Tiny->write($self->{db_connections});
	
	my $dbconnname = $self->{dbConnList_combo}->GetValue();
	
	my $username = $self->{txtDBUserName}->GetValue();
	my $password = $self->{txtDBPassword}->GetValue();
	my $dbtype = $self->{dbType}->GetValue();
	my $dbhost = $self->{txtDBHostName}->GetValue();
	my $dbname = $self->{txtDBName}->GetValue();
	my $dbinstance = $self->{txtDBInstance}->GetValue();
	my $dbport = $self->{txtDBPort}->GetValue();
	
	if( $dbconnname eq '' ) {
		print "no db connection name\n";
		return 0;
	}

	# otherwise we can save the new/changed details:
	
	# check if this connection name hasn't already been defined
	# may think about asking if they really want to over write the 
	# config
	#if( ! $self->{db_connections}->[0]->{$dbconnname} ) {
		#$self->{db_connections}->[0]->{connection} = $dbconnname;
		#$self->{db_connections}->[0]->{connection}{$dbconnname} = {
	$self->{db_connections}->[0]->{$dbconnname} = {
		dbtype => $dbtype,
		dbhost => $dbhost,
		dbport => $dbport,
		dbname => $dbname,
		dbinstance => $dbinstance,
		username => $username,
		password => $password,  # needs to be hashsed
		};
	
	#}
	#else {
	#	print "Already an entry for this connection name - ask to over write\n";
	#	return 0;
	#}
	my $ok = $self->{db_connections}->write( $self->{config_path} );
	if( ! $ok ) {
		print "Error??? " . $self->{db_connections}->errstr . "\n";
	}
}



=pod 

=head2 _validate_form_fields

Validates the form and returns a hash of the values

=cut

sub _validate_form_fields {
	my $self = shift;
	print "Checking that form is filled out\n";
	
	my $dbconnname = $self->{dbConnList_combo}->GetValue();
	
	my $username = $self->{txtDBUserName}->GetValue();
	my $password = $self->{txtDBPassword}->GetValue();
	my $dbtype = $self->{dbType}->GetValue();
	my $dbhost = $self->{txtDBHostName}->GetValue();
	my $dbname = $self->{txtDBName}->GetValue();
	my $dbinstance = $self->{txtDBInstance}->GetValue();
	my $dbport = $self->{txtDBPort}->GetValue();
	
	
	# need a dbconn name
	if( $dbconnname eq '' ) {
		# TODO DIALOG - Missing connection name
		print "No Conn Name, can't go on\n";
		return undef;
		
	}
	
	if( $dbtype eq '' ) {
		# TODO DIALOG - Missing DBType
		print "dbtype has not been defined\n";
		return undef;
	}
	
	my $dbconn_details = {
		dbconnname => $dbconnname,
		
	};
	return $dbconn_details;
	
}

=pod


=cut 

sub _db_connection_list {
	my $self = shift;
	
	my $sizer = $self->_sizer;
	
	my $dbList_sizer = Wx::BoxSizer->new( Wx::wxHORIZONTAL );
	
	#my $numElements =scalar(@dbTypes);
	my $combo = Wx::ComboBox->new(
			$self,
			-1,
			'',			# empty string
			[-1,-1],		#pos
			[-1,-1],		#size
			[ keys( %dbTypes ) ],
			Wx::wxCB_DROPDOWN | Wx::wxCB_SORT,
		);
	
	$self->{db_combo} = $combo;
	
	my $lblDBType = Wx::StaticText->new( $self, -1, _T('Database Type:'),[-1, -1], [170,-1], Wx::wxALIGN_CENTRE|Wx::wxALIGN_RIGHT  );
	$dbList_sizer->Add($lblDBType); #, 0, Wx::wxALL|Wx::wxEXPAND, 2
	$dbList_sizer->Add($combo); #, 1, Wx::wxALL|Wx::wxEXPAND, 2
	
	$self->{dbType} = $combo;
	
	Wx::Event::EVT_COMBOBOX($self, $combo, sub{ $self->on_db_select(); } );
	
	$sizer->Add($dbList_sizer);
	
}

=pod

Dropdown list of existing datbase connections.

=cut

sub _existing_db_connections {
	my $self = shift;
	
	# place holder for now
	#my @connectionList = qw/RABBIT\\DBINSTANCE/;
	
	#my @documents = Load( $self->{db_connections} );
	#print "Dumper:\n" . Dumper(@documents) . "\n";
	my @connectionList = keys( %{ $self->{db_connections}->[0] } );
	print "Dumper:\n" . Dumper($self->{db_connections} ) . "\n";
	my $sizer = $self->_sizer;
	
	my $dbConnList_sizer = Wx::BoxSizer->new( Wx::wxHORIZONTAL );
	
	my $combo = Wx::ComboBox->new(
			$self,
			-1,
			'',			# empty string
			[-1,-1],		# pos
			[-1,-1],		# size
			\@connectionList,
			Wx::wxCB_DROPDOWN | Wx::wxCB_SORT,
		);
	
	$self->{dbConnList_combo} = $combo;
	
	my $lblDBConnList = Wx::StaticText->new( $self, -1, _T('Database Connection:'),[-1, -1], [170,-1], Wx::wxALIGN_CENTRE|Wx::wxALIGN_RIGHT  );
	$dbConnList_sizer->Add($lblDBConnList); #, 0, Wx::wxALL|Wx::wxEXPAND, 2
	$dbConnList_sizer->Add($combo, 1); # , Wx::wxALL|Wx::wxEXPAND, 2
		
	Wx::Event::EVT_COMBOBOX($self, $combo, sub{ $self->_on_db_connlist_select(); } );
	
	$sizer->Add($dbConnList_sizer);	
	
	
}

sub _setup_db_conn {
	my($self) = @_;
	my $sizer = $self->_sizer;
	
	
	my $dbHostName_sizer = Wx::BoxSizer->new( Wx::wxHORIZONTAL );
	my $dbInstance_sizer = Wx::BoxSizer->new( Wx::wxHORIZONTAL );
	my $dbName_sizer = Wx::BoxSizer->new( Wx::wxHORIZONTAL );
	my $dbPort_sizer	= Wx::BoxSizer->new( Wx::wxHORIZONTAL );
	my $dbUserName_sizer = Wx::BoxSizer->new( Wx::wxHORIZONTAL );
	my $dbPassword_sizer = Wx::BoxSizer->new( Wx::wxHORIZONTAL );
	my $dbConnString_sizer = Wx::BoxSizer->new( Wx::wxHORIZONTAL );
	
	# not needed as this is provided in the dropdown list
	#my $connName_sizer =  Wx::BoxSizer->new( Wx::wxHORIZONTAL );
	#my $lblConnName = Wx::StaticText->new($self, -1, _T('Connection Name:'), [-1, -1], [170,-1], Wx::wxALIGN_CENTRE|Wx::wxALIGN_RIGHT );
	#my $txtConnName = Wx::TextCtrl->new( $self, -1, '' );
	
	#$connName_sizer->Add($lblConnName, 0, Wx::wxALIGN_CENTRE|Wx::wxALIGN_RIGHT|Wx::wxEXPAND, 2);
	#$connName_sizer->Add($txtConnName, 1); # , 1, Wx::wxEXPAND, 2
	
	my $lblDBHostName = Wx::StaticText->new($self, -1, _T('Database Host Name:'), [-1, -1], [170,-1], Wx::wxALIGN_CENTRE|Wx::wxALIGN_RIGHT );
	my $txtDBHostName = Wx::TextCtrl->new( $self, -1, '' );

	$dbHostName_sizer->Add($lblDBHostName, 0); #, 0, Wx::wxALL|Wx::wxRIGHT, 2
	$dbHostName_sizer->Add($txtDBHostName, 1 ); #, 1, Wx::wxALL, 2
	
	#Wx::Event::EVT_TEXT($self, $txtDBName, sub { $_[0]->_update_conn_string('DBHostName', $txtDBName->GetValue() ); }  );
	
	my $lblDBInstance = Wx::StaticText->new($self, -1, _T('Database Instance Name:'),[-1, -1], [170,-1], Wx::wxALIGN_CENTRE|Wx::wxALIGN_RIGHT );
	my $txtDBInstance = Wx::TextCtrl->new( $self, -1, '' );
	
	$dbInstance_sizer->Add($lblDBInstance, 0); #, 1, Wx::wxALL|Wx::wxEXPAND, 2
	$dbInstance_sizer->Add($txtDBInstance, 1); #, 1, Wx::wxALL|Wx::wxEXPAND, 2
	
	my $lblDBName = Wx::StaticText->new($self, -1, _T('Database Name:'),[-1, -1], [170,-1], Wx::wxALIGN_CENTRE|Wx::wxALIGN_RIGHT );
	my $txtDBName = Wx::TextCtrl->new( $self, -1, '' );
	
	$dbName_sizer->Add($lblDBName, 0); #, 1, Wx::wxEXPAND, 5
	$dbName_sizer->Add($txtDBName, 1); #, 1, Wx::wxEXPAND, 5
	
	my $lblDBPort = Wx::StaticText->new($self, -1, _T('Port:'),[-1, -1], [170,-1], Wx::wxALIGN_CENTRE|Wx::wxALIGN_RIGHT );
	my $txtDBPort = Wx::TextCtrl->new( $self, -1, '' );
	
	
	
	$dbPort_sizer->Add($lblDBPort, 0); #, 1, Wx::wxALL|Wx::wxEXPAND, 2
	$dbPort_sizer->Add($txtDBPort, 1); #, 1, Wx::wxALL|Wx::wxEXPAND, 2
	
	my $lblDBUserName = Wx::StaticText->new($self, -1, _T('User Name:'),[-1, -1], [170,-1], Wx::wxALIGN_CENTRE|Wx::wxALIGN_RIGHT );
	my $txtDBUserName = Wx::TextCtrl->new( $self, -1, '' );
	
	
	
	$dbUserName_sizer->Add($lblDBUserName, 0); #, 0, Wx::wxALL|Wx::wxEXPAND, 2
	$dbUserName_sizer->Add($txtDBUserName, 1); #, 0, Wx::wxALL|Wx::wxEXPAND, 2
	
	my $lblDBPassword = Wx::StaticText->new($self, -1, _T('Password:'), [-1, -1], [170,-1], Wx::wxALIGN_CENTRE|Wx::wxALIGN_RIGHT );
	my $txtDBPassword = Wx::TextCtrl->new( $self, -1, '', [-1,-1], [-1,-1], Wx::wxTE_PASSWORD );
	
	$dbPassword_sizer->Add($lblDBPassword, 0); #, 0, Wx::wxALL|Wx::wxEXPAND, 2
	$dbPassword_sizer->Add($txtDBPassword, 1); #, 0, Wx::wxALL|Wx::wxEXPAND, 2
	
	#my $lblDBConnString = Wx::StaticText->new($self, -1, _T('DB Connection String:') );
	#my $txtDBConnTxt = Wx::TextCtrl->new(	$self, 
	#					-1, 
	#					_T(''),
	#					[-1,-1],
	#					[600,-1], 
	#					Wx::wxTE_READONLY
	#				);
	
	#$dbConnString_sizer->Add($lblDBConnString); # , 0, Wx::wxALL|Wx::wxEXPAND, 2
	#$dbConnString_sizer->Add($txtDBConnTxt); # , 0, Wx::wxALL|Wx::wxEXPAND, 2
	
	#$sizer->Add($connName_sizer, 0, Wx::wxALL|Wx::wxEXPAND, 2);
	
	$sizer->Add($dbHostName_sizer, 0, Wx::wxALL|Wx::wxEXPAND, 2);
	$sizer->Add($dbInstance_sizer, 0, Wx::wxALL|Wx::wxEXPAND, 2);
	$sizer->Add($dbName_sizer, 0, Wx::wxALL|Wx::wxEXPAND, 2);
	$sizer->Add($dbPort_sizer, 0, Wx::wxALL|Wx::wxEXPAND, 2);
	$sizer->Add($dbUserName_sizer, 0, Wx::wxALL|Wx::wxEXPAND, 2);
	$sizer->Add($dbPassword_sizer, 0, Wx::wxALL|Wx::wxEXPAND, 2);
	#$sizer->Add($dbConnString_sizer, 0, Wx::wxALL|Wx::wxEXPAND, 2);
	
	
	$self->{txtDBHostName} = $txtDBHostName;
	$self->{txtDBPort} = $txtDBPort;
	$self->{txtDBUserName} = $txtDBUserName;
	$self->{txtDBPassword} = $txtDBPassword;
	$self->{txtDBName} = $txtDBName;
	$self->{txtDBInstance} = $txtDBInstance;
	
	#$self->{txtDBConnTxt} = $txtDBConnTxt;
}

sub get_connection {
	my $self = shift;
	
	my $username = $self->{txtDBUserName}->GetValue();
	my $password = $self->{txtDBPassword}->GetValue();
	my $dbtype = $self->{dbType}->GetValue();
	my $dbhost = $self->{txtDBHostName}->GetValue();
	my $dbname = $self->{txtDBName}->GetValue();
	my $dbinstance = $self->{txtDBInstance}->GetValue();
	my $dbport = $self->{txtDBPort}->GetValue();
	my %connDetails = ( 
			'username'   => $username,
			'password'   => $password,
			'dbtype'     => $dbtype,
			'dbhost'     => $dbhost,
			'dbinstance' => $dbinstance,
			'dbport'     => $dbport,
			'dbname'     => $dbname,
			
		);
	return \%connDetails;
	
}

sub _update_conn_string {
	my($self, $field, $value) = @_;
	
	my $dbHost = "Server";
	my $instance = "";
	my $dbUserName = "User";
	my $dbPass = "Password";
	
	
	$self->{txtDBConnTxt}->ChangeValue("$field=$value");
	
}


=pod 

	Redraw the dialog to suit db type.

=cut 

sub on_db_select {
	my ($self) = @_;
	
	my $dbType = $self->{db_combo}->GetValue();
	print "DBType is: $dbType\n";
	
	$self->{txtDBPort}->SetValue($dbTypes{ $self->{db_combo}->GetValue() }->{port} );
	
	# SQLite requires a browse file dialog
	
	
	#$self->_setup_db_conn();
	#$self->Update();
	
	
}

sub _on_db_connlist_select {
	my $self = shift;
	my $dbConn = $self->{dbConnList_combo}->GetValue();
	print "Connecting to: $dbConn\n";
	
	$self->{db_combo}->SetValue( $self->{db_connections}->[0]->{$dbConn}->{dbtype} );
	$self->{txtDBHostName}->SetValue( $self->{db_connections}->[0]->{$dbConn}->{dbhost} );
	$self->{txtDBPort}->SetValue( $self->{db_connections}->[0]->{$dbConn}->{dbport} );
	$self->{txtDBName}->SetValue( $self->{db_connections}->[0]->{$dbConn}->{dbname} );
	$self->{txtDBInstance}->SetValue( $self->{db_connections}->[0]->{$dbConn}->{dbinstsance} );
	
	$self->{txtDBUserName}->SetValue( $self->{db_connections}->[0]->{$dbConn}->{username} );
	$self->{txtDBPassword}->SetValue( $self->{db_connections}->[0]->{$dbConn}->{password} );
	
}

sub _reset_form {
	my $self = shift;
	$self->{db_combo}->SetValue('');
	$self->{dbConnList_combo}->SetValue('');
	
	$self->{txtDBHostName}->SetValue('');
	$self->{txtDBPort}->SetValue('');
	$self->{txtDBUserName}->SetValue('');
	$self->{txtDBPassword}->SetValue('');
	$self->{txtDBName}->SetValue('');
	$self->{txtDBInstance}->SetValue('');
	
}


1;


# Copyright 2008-2010 The Padre development team as listed in Padre.pm.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.