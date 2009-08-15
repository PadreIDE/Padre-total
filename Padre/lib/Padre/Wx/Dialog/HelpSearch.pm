package Padre::Wx::Dialog::HelpSearch;

use warnings;
use strict;

# package exports and version
our $VERSION = '0.43';
our @ISA     = 'Wx::Dialog';

# module imports
use Padre::Wx       ();
use Padre::Wx::Icon ();

# accessors
use Class::XSAccessor accessors => {
	_hbox          => '_hbox',          # horizontal box sizer
	_vbox          => '_vbox',          # vertical box sizer
	_search_text   => '_search_text',   # search text control
	_list          => '_list',          # matches list
	_targets_index => '_targets_index', # targets index
	_help_viewer   => '_help_viewer',   # HTML Help Viewer
	_main          => '_main',          # Padre's main window
	_topic         => '_topic',         # default help topic
};

# -- constructor
sub new {
	my ( $class, $main, %opt ) = @_;

	# create object
	my $self = $class->SUPER::new(
		$main,
		-1,
		Wx::gettext('Help Search'),
		Wx::wxDefaultPosition,
		Wx::wxDefaultSize,
		Wx::wxDEFAULT_FRAME_STYLE | Wx::wxTAB_TRAVERSAL,
	);

	$self->_main($main);
	$self->_topic( $opt{topic} // '' );

	# Dialog's icon as is the same as Padre
	$self->SetIcon(Padre::Wx::Icon::PADRE);

	# create dialog
	$self->_create;

	# fit and center the dialog
	$self->Fit;
	$self->CentreOnParent;

	return $self;
}


# -- event handler

#
# Fetches the current selection's help HTML
#
sub display_help_in_viewer {
	my $self = shift;

	my $help_html;
	my $selection = $self->_list->GetSelection();
	if ( $selection != -1 ) {
		my $help_target = $self->_list->GetClientData($selection);

		if ($help_target) {
			my $doc = Padre::Current->document;
			if ( $doc && $doc->can('on_help_render') ) {
				eval {
					my $help_location;
					( $help_html, $help_location ) = $doc->on_help_render($help_target);
					$self->SetTitle( Wx::gettext('Help Search') . " - " . $help_location );
				};
				if ($@) {
					warn "Error while calling on_help_render: $@\n";
				}
			}
		}
	}

	if ( not $help_html ) {
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
	$self->_hbox( Wx::BoxSizer->new(Wx::wxHORIZONTAL) );
	$self->_vbox( Wx::BoxSizer->new(Wx::wxVERTICAL) );

	# create the controls
	$self->_create_controls;
	$self->_create_buttons;

	# wrap everything in a box to add some padding
	$self->SetMinSize( [ 640, 480 ] );
	$self->SetSizer( $self->_hbox );

	# focus on the search text box
	$self->_search_text->SetFocus();

	$self->_search_text->SetValue( $self->_topic );
	$self->_update_list_box;
}

#
# create the buttons pane.
#
sub _create_buttons {
	my $self = shift;

	my $close_button = Wx::Button->new( $self, Wx::wxID_CANCEL, Wx::gettext('&Close') );
	$self->_vbox->Add( $close_button, 0, Wx::wxALL | Wx::wxALIGN_LEFT, 5 );
}

#
# create controls in the dialog
#
sub _create_controls {
	my $self = shift;

	# search textbox
	my $search_label = Wx::StaticText->new(
		$self, -1,
		Wx::gettext('&Type a help topic to read:')
	);
	$self->_search_text( Wx::TextCtrl->new( $self, -1, '' ) );

	# matches result list
	my $matches_label = Wx::StaticText->new(
		$self, -1,
		Wx::gettext('&Matching Help Topics:')
	);
	$self->_list(
		Wx::ListBox->new(
			$self,
			-1,
			Wx::wxDefaultPosition,
			Wx::wxDefaultSize,
			[],
			Wx::wxLB_SINGLE
		)
	);

	# HTML Help Viewer
	require Padre::Wx::HtmlWindow;
	$self->_help_viewer(
		Padre::Wx::HtmlWindow->new(
			$self,
			-1,
			Wx::wxDefaultPosition,
			Wx::wxDefaultSize,
			Wx::wxBORDER_STATIC
		)
	);
	$self->_help_viewer->SetPage('');


	$self->_vbox->Add( $search_label,       0, Wx::wxALL | Wx::wxEXPAND, 2 );
	$self->_vbox->Add( $self->_search_text, 0, Wx::wxALL | Wx::wxEXPAND, 2 );
	$self->_vbox->Add( $matches_label,      0, Wx::wxALL | Wx::wxEXPAND, 2 );
	$self->_vbox->Add( $self->_list,        1, Wx::wxALL | Wx::wxEXPAND, 2 );
	$self->_hbox->Add( $self->_vbox,        0, Wx::wxALL | Wx::wxEXPAND, 2 );
	$self->_hbox->Add(
		$self->_help_viewer,                                                        1,
		Wx::wxALL | Wx::wxALIGN_TOP | Wx::wxALIGN_CENTER_HORIZONTAL | Wx::wxEXPAND, 1
	);

	$self->_setup_events();

	return;
}

#
# Adds various events
#
sub _setup_events {
	my $self = shift;

	Wx::Event::EVT_CHAR(
		$self->_search_text,
		sub {
			my $this  = shift;
			my $event = shift;
			my $code  = $event->GetKeyCode;

			if ( $code == Wx::WXK_DOWN || $code == Wx::WXK_PAGEDOWN ) {
				$self->_list->SetFocus();
			}

			$event->Skip(1);
		}
	);

	Wx::Event::EVT_TEXT(
		$self,
		$self->_search_text,
		sub {

			$self->_update_list_box;

			return;
		}
	);

	Wx::Event::EVT_LISTBOX(
		$self,
		$self->_list,
		sub {
			$self->display_help_in_viewer;
		}
	);

}

#
# Focus on it if it shown or restart its state and show it if it is hidden.
#
sub showIt {
	my $self = shift;

	if ( $self->IsShown ) {
		$self->SetFocus;
	} else {
		$self->_search_text->ChangeValue('');
		$self->_search;
		$self->_update_list_box;
		$self->Show(1);
	}
}

#
# Search for files and cache result
#
sub _search() {
	my $self = shift;

	# a default..
	my @empty = ();
	$self->_targets_index( \@empty );

	# Generate a sorted file-list based on filename
	my $doc = Padre::Current->document;
	if ( $doc && $doc->can('on_help_list') ) {
		eval {
			my @targets_index = $doc->on_help_list;
			$self->_targets_index( \@targets_index );
		};
		if ($@) {
			warn "Error while calling on_help_list: $@\n";
		}
	}

	return;
}

#
# Update matches list box from matched files list
#
sub _update_list_box() {
	my $self = shift;

	if ( not $self->_targets_index ) {
		$self->_search;
	}

	my $search_expr = $self->_search_text->GetValue();
	$search_expr = quotemeta $search_expr;

	#Populate the list box now
	$self->_list->Clear();
	my $pos = 0;
	foreach my $target ( @{ $self->_targets_index } ) {
		if ( $target =~ /^$search_expr$/i ) {
			$self->_list->Insert( $target, 0, $target );
			$pos++;
		} elsif ( $target =~ /$search_expr/i ) {
			$self->_list->Insert( $target, $pos, $target );
			$pos++;
		}
	}
	if ( $pos > 0 ) {
		$self->_list->Select(0);
	}
	$self->display_help_in_viewer;

	return;
}


1;


__END__

=head1 NAME

Padre::Wx::Dialog::HelpSearch - Padre Shiny Help Search Dialog

=head1 DESCRIPTION

This opens a dialog where you can search for help topics... 

Note: This used to be Perl 6 Help Dialog (in Padre::Plugin::Perl6) and but it
has been moved to Padre core

=head1 AUTHOR

Ahmad M. Zawawi C<< <ahmad.zawawi at gmail.com> >>

=head1 COPYRIGHT & LICENSE

Copyright 2008-2009 The Padre development team as listed in Padre.pm.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

=cut

# Copyright 2008-2009 The Padre development team as listed in Padre.pm.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.
