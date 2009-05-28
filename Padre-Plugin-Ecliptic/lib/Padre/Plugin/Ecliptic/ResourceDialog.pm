package Padre::Plugin::Ecliptic::ResourceDialog;

use warnings;
use strict;

use Class::XSAccessor accessors => {
	_plugin      => '_plugin',       # plugin to be configured
	_sizer       => '_sizer',        # window sizer
	_search_text => '_search_text',	 # search text box
};

our $VERSION = '0.40';

use Padre::Current;
use Padre::Wx ();
use Padre::Util   ('_T');

use base 'Wx::Dialog';


# -- constructor
sub new {
	my ($class, $plugin) = @_;

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
	$self->_plugin($plugin);

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
	my $plugin = $self->_plugin;

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

	# focus on the search text box
	$self->_search_text->SetFocus();
	
	# wrap everything in a vbox to add some padding
	$self->SetSizerAndFit($sizer);
	$sizer->SetSizeHints($self);
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
	my $matches_label = Wx::StaticText->new( $self, -1, _T('&Matching Items:') );
	my $matches_list = Wx::ListBox->new( $self, -1, [-1, -1], [-1, -1], [], Wx::wxLB_EXTENDED );

	# Shows how many items are selected and information about what is selected
	my $status_text =  Wx::StaticText->new( $self, -1, '' );
	
	$self->_sizer->AddSpacer(10);
	$self->_sizer->Add( $search_label, 0, Wx::wxALL|Wx::wxEXPAND, 2 );
	$self->_sizer->Add( $self->_search_text, 0, Wx::wxALL|Wx::wxEXPAND, 5 );
	$self->_sizer->Add( $matches_label, 0, Wx::wxALL|Wx::wxEXPAND, 2 );
	$self->_sizer->Add( $matches_list, 0, Wx::wxALL|Wx::wxEXPAND, 2 );
	$self->_sizer->Add( $status_text, 0, Wx::wxALL|Wx::wxEXPAND, 10 );
	
	my @files;
	Wx::Event::EVT_TEXT( $self, $self->_search_text, sub {

		if(not @files) {
			$status_text->SetLabel( _T("Reading current directory. Please wait...") );
			require File::Find::Rule;
			@files = File::Find::Rule->file()
				->name( '*' )
				->in( Cwd::getcwd() );
			$status_text->SetLabel( _T("Done") );
		}
		$matches_list->Clear();
		my $search_expr = $self->_search_text->GetValue();
		#XXX - escape search string
		$search_expr =~ s/\*/.+/g;
		$search_expr =~ s/\?/./g;
		#XXX - it should be sorted in another list first
		foreach my $file (@files) {
			my $filename = File::Basename::fileparse($file);
			if($filename =~ /^$search_expr/) {
				$matches_list->Insert($filename, 0);
			}
		}
	});
	
	Wx::Event::EVT_LISTBOX( $self, $matches_list, sub {
		my $self  = shift;
		my @matches = $matches_list->GetSelections();
		my $num_selected =  scalar @matches;
		if($num_selected > 1) {
			$status_text->SetLabel("" . scalar @matches . _T(" items selected"));
		} else {
			$status_text->SetLabel($matches_list->GetString($matches[0]));
		}
	});
	
}

1;