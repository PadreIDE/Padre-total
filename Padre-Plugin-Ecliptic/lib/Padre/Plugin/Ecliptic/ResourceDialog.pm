package Padre::Plugin::Ecliptic::ResourceDialog;

use warnings;
use strict;

use Class::XSAccessor accessors => {
	_sizer        => '_sizer',           # window sizer
	_search_text  => '_search_text',	 # search text box
	_matches_list => '_matches_list',	 # matches list box
	_directory    => '_directory',	     # searched directory
};

our $VERSION = '0.02';

use Padre::Wx ();
use Padre::Current ();
use Padre::Util   ('_T');

use base 'Wx::Dialog';


# -- constructor
sub new {
	my ($class, $plugin, %opt) = @_;

	#Check if we have an open file so we can use its directory
	my $filename = Padre::Current->filename;
	my $directory;
	if($filename) {
		# current document's project or base directory
		$directory = Padre::Util::get_project_dir($filename) 
			|| File::Basename::dirname($filename);
	} else {
		# current working directory
		$directory = Cwd::getcwd();
	}
	
	# create object
	my $self = $class->SUPER::new(
		Padre::Current->main,
		-1,
		_T('Open Resource'),
		Wx::wxDefaultPosition,
		Wx::wxDefaultSize,
		Wx::wxDEFAULT_FRAME_STYLE|Wx::wxTAB_TRAVERSAL,
	);

	$self->SetIcon( Wx::GetWxPerlIcon() );
	$self->_directory($directory);

	# create dialog
	$self->_create;

	return $self;
}


# -- event handler

#
# $self->_on_ok_button_clicked;
#
# handler called when the ok button has been clicked.
# 
sub _on_ok_button_clicked {
	my ($self) = @_;

	my $main = Padre->ide->wx->main;

	#Open the selected resources here if the user pressed OK
	my @selections = $self->_matches_list->GetSelections();
	foreach my $selection (@selections) {
		my $filename = $self->_matches_list->GetClientData($selection);
		# try to open the file now
		$main->setup_editor($filename);
	}

	$self->Destroy;
}


# -- private methods

#
# $self->_create;
#
# create the dialog itself.
#
# no params, no return values.
#
sub _create {
	my ($self) = @_;

	# create sizer that will host all controls
	my $sizer = Wx::BoxSizer->new( Wx::wxVERTICAL );
	$self->_sizer($sizer);

	# create the controls
	$self->_create_controls;
	$self->_create_buttons;

	# wrap everything in a vbox to add some padding
	$self->SetSizerAndFit($sizer);
	$sizer->SetSizeHints($self);

	# focus on the search text box
	$self->_search_text->SetFocus();
}

#
# $dialog->_create_buttons;
#
# create the buttons pane.
#
# no params. no return values.
#
sub _create_buttons {
	my ($self) = @_;
	my $sizer  = $self->_sizer;

	my $butsizer = $self->CreateStdDialogButtonSizer(Wx::wxOK|Wx::wxCANCEL);
	$sizer->Add($butsizer, 0, Wx::wxALL|Wx::wxEXPAND|Wx::wxALIGN_CENTER, 5 );
	Wx::Event::EVT_BUTTON( $self, Wx::wxID_OK, \&_on_ok_button_clicked );
}

#
# $dialog->_create_controls;
#
# create the pane to choose the various configuration parameters.
#
# no params. no return values.
#
sub _create_controls {
	my ($self) = @_;

	# search textbox
	my $search_label = Wx::StaticText->new( $self, -1, 
		_T('&Select an item to open (? = any character, * = any string):') );
	$self->_search_text( Wx::TextCtrl->new( $self, -1, '' ) );
	
	# matches result list
	my $matches_label = Wx::StaticText->new( $self, -1, 
		_T('&Matching Items:') );
	$self->_matches_list( Wx::ListBox->new( $self, -1, [-1, -1], [-1, -1], [], 
		Wx::wxLB_EXTENDED ) );

	# Shows how many items are selected and information about what is selected
	my $status_text =  Wx::StaticText->new( $self, -1, '' );
	
	$self->_sizer->AddSpacer(10);
	$self->_sizer->Add( $search_label, 0, Wx::wxALL|Wx::wxEXPAND, 2 );
	$self->_sizer->Add( $self->_search_text, 0, Wx::wxALL|Wx::wxEXPAND, 5 );
	$self->_sizer->Add( $matches_label, 0, Wx::wxALL|Wx::wxEXPAND, 2 );
	$self->_sizer->Add( $self->_matches_list, 0, Wx::wxALL|Wx::wxEXPAND, 2 );
	$self->_sizer->Add( $status_text, 0, Wx::wxALL|Wx::wxEXPAND, 10 );

	Wx::Event::EVT_CHAR( $self->_search_text, sub {
		my $this  = shift;
		my $event = shift;
		my $code  = $event->GetKeyCode;

		if ( $code == Wx::WXK_DOWN ) {
			$self->_matches_list->SetFocus();
		}

		$event->Skip(1);		
	});
	
	my @files;
	Wx::Event::EVT_TEXT( $self, $self->_search_text, sub {

		if(not @files) {
			$status_text->SetLabel( _T("Reading items. Please wait...") );

			# Generate a sorted file-list based on filename
			require File::Find::Rule;
			@files = sort { 
				File::Basename::fileparse($a) cmp File::Basename::fileparse($b)
			} File::Find::Rule->file()->name( '*' )->in( $self->_directory ); 
			
			$status_text->SetLabel( _T("Done") );
		}

		my $search_expr = $self->_search_text->GetValue();

		#quote the search string to make it safer
		#and then tranform * and ? into .* and .
		$search_expr = quotemeta $search_expr;
		$search_expr =~ s/\\\*/.*?/g;
		$search_expr =~ s/\\\?/./g;

		#Populate the list box now
		$self->_matches_list->Clear();
		my $pos = 0;
		foreach my $file (@files) {
			my $filename = File::Basename::fileparse($file);
			if($filename =~ /^$search_expr/i) {
				$self->_matches_list->Insert($filename, $pos, $file);
				$pos++;
			}
		}
		if($pos > 0) {
			$self->_matches_list->Select(0);
		}
		$status_text->SetLabel("" . ($pos+1) . _T(" item(s) found"));
		
		return;
	});
	
	Wx::Event::EVT_LISTBOX( $self, $self->_matches_list, sub {
		my $self  = shift;
		my @matches = $self->_matches_list->GetSelections();
		my $num_selected =  scalar @matches;
		if($num_selected > 1) {
			$status_text->SetLabel(
				"" . scalar @matches . _T(" items selected"));
		} else {
			$status_text->SetLabel(
				$self->_matches_list->GetString($matches[0]));
		}
		
		return;
	});
	
}

1;