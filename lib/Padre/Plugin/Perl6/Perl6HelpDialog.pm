package Padre::Plugin::Perl6::Perl6HelpDialog;

use warnings;
use strict;

# package exports and version
our $VERSION = '0.49';
our @EXPORT_OK = ();

# module imports
use Padre::Wx ();

# is a subclass of Wx::Dialog
use base 'Wx::Dialog';

# accessors
use Class::XSAccessor accessors => {
	_sizer             => '_sizer',              # window sizer
	_search_text       => '_search_text',        # search text control
	_list      => '_list',       # matches list
	_targets_index     => '_targets_index',      # targets index
	_plugin            => '_plugin',             # plugin object
};

# -- constructor
sub new {
	my ($class, $plugin, %opt) = @_;

	my $main = $plugin->main;
	
	# create object
	my $self = $class->SUPER::new(
		$main,
		-1,
		Wx::gettext('Perl 6 Help'),
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
# handler called when the ok button has been clicked.
# 
sub _on_ok_button_clicked {
	my ($self) = @_;

	my $main = $self->_plugin->main;

	#Open the selected resources here if the user pressed OK
	my $selection = $self->_list->GetSelection();
	my $help_target = $self->_list->GetClientData($selection);
	if($help_target) {
		require App::Grok;
		my $grok = App::Grok->new;
		my $grok_text = $grok->render_target($help_target,'text');
		if($grok_text) {
			Wx::MessageBox(
				$grok_text,
				'Perl 6 Help',
				Wx::wxOK,
				$main,
			);
		} else {
			Wx::MessageBox(
				'Topic not found!',
				'Perl 6 Help',
				Wx::wxOK,
				$main,
			);
		}
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
	
	$self->_update_list_box;
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
	$self->_list( Wx::ListBox->new( $self, -1, [-1, -1], [400, 300], [], 
		Wx::wxLB_SINGLE ) );

	$self->_sizer->AddSpacer(10);
	$self->_sizer->Add( $search_label, 0, Wx::wxALL|Wx::wxEXPAND, 2 );
	$self->_sizer->Add( $self->_search_text, 0, Wx::wxALL|Wx::wxEXPAND, 2 );
	$self->_sizer->Add( $matches_label, 0, Wx::wxALL|Wx::wxEXPAND, 2 );
	$self->_sizer->Add( $self->_list, 0, Wx::wxALL|Wx::wxEXPAND, 2 );

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
			$self->_list->SetFocus();
		}

		$event->Skip(1);		
	});

	Wx::Event::EVT_TEXT( $self, $self->_search_text, sub {

		$self->_update_list_box;
		
		return;
	});
	
	Wx::Event::EVT_LISTBOX_DCLICK( $self, $self->_list, sub {
		$self->_on_ok_button_clicked();
		$self->EndModal(0);
	});
}

#
# Search for files and cache result
#
sub _search() {
	my $self = shift;
	
	# Generate a sorted file-list based on filename
	require App::Grok;
	my $grok = App::Grok->new;
	my @targets_index = sort $grok->target_index();

	$self->_targets_index( \@targets_index ); 
	
	return;
}

#
# Update matches list box from matched files list
#
sub _update_list_box() {
	my $self = shift;
	
	if(not $self->_targets_index) {
		$self->_search();
	}

	my $search_expr = $self->_search_text->GetValue();

	#quote the search string to make it safer
	#and then tranform * and ? into .* and .
	$search_expr = quotemeta $search_expr;
	$search_expr =~ s/\\\*/.*?/g;
	$search_expr =~ s/\\\?/./g;

	#Populate the list box now
	$self->_list->Clear();
	my $pos = 0;
	foreach my $target (@{$self->_targets_index}) {
		if($target =~ /^$search_expr/i) {
			$self->_list->Insert($target, $pos, $target);
			$pos++;
		}
	}
	if($pos > 0) {
		$self->_list->Select(0);
	}
			
	return;
}


1;