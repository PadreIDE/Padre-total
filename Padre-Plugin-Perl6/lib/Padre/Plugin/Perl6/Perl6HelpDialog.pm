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
	_hbox              => '_hbox',               # horizontal box sizer
	_vbox              => '_vbox',               # vertical box sizer
	_search_text       => '_search_text',        # search text control
	_list              => '_list',               # matches list
	_targets_index     => '_targets_index',      # targets index
	_help_viewer       => '_help_viewer',        # HTML Help Viewer
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
		Wx::gettext('Perl 6 Help (Powered by App::Grok)'),
		Wx::wxDefaultPosition,
		Wx::wxDefaultSize,
		Wx::wxDEFAULT_FRAME_STYLE|Wx::wxTAB_TRAVERSAL,
	);

	$self->SetIcon( Wx::GetWxPerlIcon() );
	$self->_plugin($plugin);

	# create dialog
	$self->_create;
	
	$self->_search_text->SetValue($opt{topic} // '');

	return $self;
}


# -- event handler

#
# Fetches the current selection's help HTML via App::Grok
#
sub display_help_in_viewer {
	my $self = shift;

	my $selection = $self->_list->GetSelection();
	my $help_target = $self->_list->GetClientData($selection);
	my $help_html;
	if($help_target) {
		require App::Grok;
		eval {
			my $grok = App::Grok->new;
			$help_html = $grok->render_target($help_target,'xhtml');
		};
	}
	
	if(not $help_html) {
		$help_html = '<b>No Help found</b>';
	}
	
	$self->_help_viewer->SetPage($help_html);

	return;
}

# -- private methods

#
# create the dialog itself.
#
sub _create {
	my $self = shift;

	# create sizer that will host all controls
	$self->_hbox( Wx::BoxSizer->new( Wx::wxHORIZONTAL ) );
	$self->_vbox( Wx::BoxSizer->new( Wx::wxVERTICAL ) );

	# create the controls
	$self->_create_controls;
	$self->_create_buttons;

	# wrap everything in a box to add some padding
	$self->SetSizerAndFit($self->_hbox);
	$self->_hbox->SetSizeHints($self);

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
	my $self = shift;

	my $close_button = Wx::Button->new( $self, Wx::wxID_CANCEL, Wx::gettext('Close') );
	$self->_vbox->Add($close_button, 0, Wx::wxALL|Wx::wxALIGN_LEFT, 5 );
}

#
# create controls in the dialog
#
sub _create_controls {
	my $self = shift;

	# search textbox
	my $search_label = Wx::StaticText->new( $self, -1, 
		Wx::gettext('&Type a help topic to read:') );
	$self->_search_text( Wx::TextCtrl->new( $self, -1, '' ) );
	
	# matches result list
	my $matches_label = Wx::StaticText->new( $self, -1, 
		Wx::gettext('&Matching Help Topics:') );
	$self->_list( Wx::ListBox->new( $self, -1, [-1, -1], [200, 300], [], 
		Wx::wxLB_SINGLE ) );
		
	# HTML Help Viewer
	require Padre::Wx::HtmlWindow;
	$self->_help_viewer( Padre::Wx::HtmlWindow->new($self, -1, [-1,-1], [350, 300], Wx::wxBORDER_STATIC ) );
	$self->_help_viewer->SetPage('');

	
	$self->_vbox->AddSpacer(10);
	$self->_vbox->Add( $search_label, 0, Wx::wxALL|Wx::wxEXPAND, 2 );
	$self->_vbox->Add( $self->_search_text, 0, Wx::wxALL|Wx::wxEXPAND, 2 );
	$self->_vbox->Add( $matches_label, 0, Wx::wxALL|Wx::wxEXPAND, 2 );
	$self->_vbox->Add( $self->_list, 0, Wx::wxALL|Wx::wxEXPAND, 2 );
	$self->_hbox->Add( $self->_vbox, 0, Wx::wxALL|Wx::wxEXPAND, 2 );
	$self->_hbox->Add( $self->_help_viewer, 0, Wx::wxALL|Wx::wxEXPAND, 0 );

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

		if ( $code == Wx::WXK_DOWN || $code == Wx::WXK_PAGEDOWN) {
			$self->_list->SetFocus();
		}

		$event->Skip(1);		
	});

	Wx::Event::EVT_TEXT( $self, $self->_search_text, sub {

		$self->_update_list_box;
		
		return;
	});
	
	Wx::Event::EVT_LISTBOX( $self, $self->_list, sub {
		$self->display_help_in_viewer;
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
	$search_expr = quotemeta $search_expr;

	#Populate the list box now
	$self->_list->Clear();
	my $pos = 0;
	foreach my $target (@{$self->_targets_index}) {
		if($target =~ /$search_expr/i) {
			$self->_list->Insert($target, $pos, $target);
			$pos++;
		}
	}
	if($pos > 0) {
		$self->_list->Select(0);
		$self->display_help_in_viewer;
	}
			
	return;
}


1;