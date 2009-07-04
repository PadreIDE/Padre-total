package Padre::Plugin::Perl6::Perl6HelpDialog;

use warnings;
use strict;

# package exports and version
our $VERSION = '0.48';
our @EXPORT_OK = ();

# module imports
use Padre::Wx ();

# is a subclass of Wx::Dialog
use base 'Wx::Dialog';

# accessors
use Class::XSAccessor accessors => {
	_sizer             => '_sizer',              # window sizer
	_search_text       => '_search_text',	     # search text control
	_matches_list      => '_matches_list',	     # matches list
};

# -- constructor
sub new {
	my ($class, $plugin, %opt) = @_;

	#Check if we have an open file so we can use its directory
	my $main = $plugin->main;
	my $filename = (defined $main->current->document) ? $main->current->document->filename : undef;
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
		$main,
		-1,
		Wx::gettext('Open Resource'),
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

	$self->_sizer->AddSpacer(10);
	$self->_sizer->Add( $search_label, 0, Wx::wxALL|Wx::wxEXPAND, 2 );
	$self->_sizer->Add( $self->_search_text, 0, Wx::wxALL|Wx::wxEXPAND, 2 );
	$self->_sizer->Add( $matches_label, 0, Wx::wxALL|Wx::wxEXPAND, 2 );
	$self->_sizer->Add( $self->_matches_list, 0, Wx::wxALL|Wx::wxEXPAND, 2 );

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

		if(not $self->_matched_files) {
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
}

#
# Search for files and cache result
#
sub _search() {
	my $self = shift;
	
	$self->_status_text->SetLabel( Wx::gettext("Reading items. Please wait...") );

	# search and ignore rc folders (CVS,.svn,.git) if the user wants
	require File::Find::Rule;
	my $rule = File::Find::Rule->new;
	$rule->file;

	# Generate a sorted file-list based on filename
	my @matched_files = sort { 
			File::Basename::fileparse($a) cmp File::Basename::fileparse($b)
	} $rule->in( $self->_directory );

	$self->_matched_files( \@matched_files ); 
	
	$self->_status_text->SetLabel( Wx::gettext("Finished Searching") );

	return;
}

#
# Update matches list box from matched files list
#
sub _update_matches_list_box() {
	my $self = shift;
	
	my $search_expr = $self->_search_text->GetValue();

	#quote the search string to make it safer
	#and then tranform * and ? into .* and .
	$search_expr = quotemeta $search_expr;
	$search_expr =~ s/\\\*/.*?/g;
	$search_expr =~ s/\\\?/./g;

	#Populate the list box now
	$self->_matches_list->Clear();
	my $pos = 0;
	foreach my $file (@{$self->_matched_files}) {
		my $filename = File::Basename::fileparse($file);
		if($filename =~ /^$search_expr/i) {
			$self->_matches_list->Insert($filename, $pos, $file);
			$pos++;
		}
	}
	if($pos > 0) {
		$self->_matches_list->Select(0);
		$self->_status_text->SetLabel("" . ($pos+1) . Wx::gettext(' item(s) found'));
	} else {
		$self->_status_text->SetLabel(Wx::gettext('No items found'));
	}
			
	return;
}


1;