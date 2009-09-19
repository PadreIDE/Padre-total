package Padre::Wx::DocBrowser::QuickDialog;

use warnings;
use strict;

# package exports and version
our $VERSION = '0.40';
our @EXPORT_OK = ();

# module imports
use Padre::Wx ();
use Padre::Index::Kinosearch;


# is a subclass of Wx::Dialog
use base 'Wx::Dialog';

# accessors
use Class::XSAccessor accessors => {
	_sizer             => '_sizer',              # window sizer
	_search_text       => '_search_text',	     # search text control
	_matches_list      => '_matches_list',	     # matches list
	_status_text       => '_status_text',        # status label
	_index		  =>  '_index' ,
	_searcher	  =>  '_searcher' ,
	_matched_docs     => '_matched_docs',		 # matched files list
};

# -- constructor
sub new {
	my ($class, $main, %opt) = @_;

	
	# create object
	my $self = $class->SUPER::new(
		$main,
		-1,
		Wx::gettext('Quick Docs'),
		Wx::wxDefaultPosition,
		Wx::wxDefaultSize,
		Wx::wxDEFAULT_FRAME_STYLE|Wx::wxTAB_TRAVERSAL,
	);

	$self->SetIcon( Wx::GetWxPerlIcon() );
	my $index = Padre::Index::Kinosearch->new( index_directory=>'/tmp/padre-index' );
	$self->{_index} = $index;
	
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

	my $main = Padre->ide->wx->main;

	#Open the selected resources here if the user pressed OK
	my @selections = $self->_matches_list->GetSelections();
	foreach my $selection (@selections) {
		my $filename = $self->_matches_list->GetClientData($selection);
		my $doc = Padre::Document->new( filename => $filename );
		Padre->ide->wx->main->help( $doc );
		
	}

	$self->Destroy;
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
	$self->_create_controls;
	$self->_create_buttons;

	# wrap everything in a vbox to add some padding
	$self->SetSizerAndFit($sizer);
	$sizer->SetSizeHints($self);

	# center the dialog
	$self->Centre;

	# focus on the search text box
	$self->_search_text->SetFocus();
}

#
# create the buttons pane.
#
sub _create_buttons {
	my ($self) = @_;
	my $sizer  = $self->_sizer;

	my $butsizer = $self->CreateStdDialogButtonSizer(Wx::wxOK|Wx::wxCANCEL);
	$sizer->Add($butsizer, 0, Wx::wxALL|Wx::wxEXPAND|Wx::wxALIGN_CENTER, 5 );
	Wx::Event::EVT_BUTTON( $self, Wx::wxID_OK, \&_on_ok_button_clicked );
}

#
# create controls in the dialog
#
sub _create_controls {
	my ($self) = @_;

	# search textbox
	my $search_label = Wx::StaticText->new( $self, -1, 
		Wx::gettext('&Select an item to open (? = any character, * = any string):') );
	$self->_search_text( Wx::TextCtrl->new( $self, -1, '' ) );
	
	# matches result list
	my $matches_label = Wx::StaticText->new( $self, -1, 
		Wx::gettext('&Matching Items:') );
	$self->_matches_list( Wx::ListBox->new( $self, -1, [-1, -1], [400, 300], [], 
		Wx::wxLB_EXTENDED ) );

	# Shows how many items are selected and information about what is selected
	$self->_status_text( Wx::StaticText->new( $self, -1, "" ) );
	
	$self->_sizer->AddSpacer(10);
	$self->_sizer->Add( $search_label, 0, Wx::wxALL|Wx::wxEXPAND, 2 );
	$self->_sizer->Add( $self->_search_text, 0, Wx::wxALL|Wx::wxEXPAND, 2 );
	#$self->_sizer->Add( $self->_ignore_dir_check, 0, Wx::wxALL|Wx::wxEXPAND, 5);
	$self->_sizer->Add( $matches_label, 0, Wx::wxALL|Wx::wxEXPAND, 2 );
	$self->_sizer->Add( $self->_matches_list, 0, Wx::wxALL|Wx::wxEXPAND, 2 );
	$self->_sizer->Add( $self->_status_text, 0, Wx::wxALL|Wx::wxEXPAND, 10 );

	$self->_setup_events();
	
	return;
}

#
# Adds various events
#
sub _setup_events {
	my $self = shift;
	
	Wx::Event::EVT_CHAR( $self->_search_text, sub {
		my $this  = shift;
		my $event = shift;
		my $code  = $event->GetKeyCode;

		if ( $code == Wx::WXK_DOWN ) {
			$self->_matches_list->SetFocus();
		}

		$event->Skip(1);
	});

	Wx::Event::EVT_TEXT( $self, $self->_search_text, sub {

		if(not $self->_matched_docs) {
			$self->_search();
		}
		$self->_update_matches_list_box;
		
		return;
	});
	
	Wx::Event::EVT_LISTBOX( $self, $self->_matches_list, sub {
		my $self  = shift;
		my @matches = $self->_matches_list->GetSelections();
		my $num_selected =  scalar @matches;
		if($num_selected > 1) {
			$self->_status_text->SetLabel(
				"" . scalar @matches . Wx::gettext(" items selected"));
		} elsif($num_selected == 1) {
			$self->_status_text->SetLabel(
				$self->_matches_list->GetClientData($matches[0]));
		}
		
		return;
	});
	
	Wx::Event::EVT_LISTBOX_DCLICK( $self, $self->_matches_list, sub {
		$self->_on_ok_button_clicked();
		$self->EndModal(0);
	});

	Wx::Event::EVT_IDLE( $self, sub {
		# focus on the search text box
		$self->_search_text->SetFocus;
		
		# unregister from idle event
		Wx::Event::EVT_IDLE( $self, undef );
	});
}


#
# Search for files and cache result
#
sub _search() {
	my $self = shift;
	
	$self->_status_text->SetLabel( Wx::gettext("Reading items. Please wait...") );

	# Generate a sorted file-list based on filename
	my @matched_docs;
	
	$self->_matched_docs( \@matched_docs ); 
	
	$self->_status_text->SetLabel( Wx::gettext("Finished Searching") );

	return;
}

#
# Update matches list box from matched files list
#
sub _update_matches_list_box() {
	my $self = shift;
	
	my $search_expr = $self->_search_text->GetValue();
	my $index = $self->_index;
	my $hits = $index->search( $search_expr );
	$self->_matches_list->Clear();
	my $pos = 0;
	while ( my $hit = $hits->next ) {
		$self->_matches_list->Insert($hit->{title}, $pos, $hit->{file} );
		$pos++;
	}
	if($pos > 0) {
		$self->_matches_list->Select(0);
		$self->_status_text->SetLabel("" . $hits->total_hits . Wx::gettext(' item(s) found'));
	} else {
		$self->_status_text->SetLabel(Wx::gettext('No items found'));
	}
			
	return;
}


1;
