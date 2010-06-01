package Padre::Wx::FunctionList;

use 5.008005;
use strict;
use warnings;
use Scalar::Util          ();
use Params::Util          ();
use Padre::Current        ('_CURRENT');
use Padre::Task2Owner     ();
use Padre::Wx::Role::View ();
use Padre::Wx             ();

our $VERSION = '0.62';
our @ISA     = qw{
	Padre::Task2Owner
	Padre::Wx::Role::View
	Wx::Panel
};





#####################################################################
# Constructor

sub new {
	my $class = shift;
	my $main  = shift;
	my $panel = shift || $main->right;

	# Create the parent panel, which will contain the search and tree
	my $self = $class->SUPER::new(
		$panel,
		-1,
		Wx::wxDefaultPosition,
		Wx::wxDefaultSize,
	);

	# Store main for other methods
	$self->{main} = $main;

	# Temporary store for the function list.
	$self->{names} = [];

	# Create the search control
	$self->{search} = Wx::TextCtrl->new(
		$self, -1, '',
		Wx::wxDefaultPosition,
		Wx::wxDefaultSize,
		Wx::wxTE_PROCESS_ENTER | Wx::wxSIMPLE_BORDER,
	);

	# Create the functions list
	$self->{functions} = Wx::ListBox->new(
		$self,
		-1,
		Wx::wxDefaultPosition,
		Wx::wxDefaultSize,
		[],
		Wx::wxLB_SINGLE | Wx::wxBORDER_NONE
	);

	# Create a sizer
	my $sizerv = Wx::BoxSizer->new(Wx::wxVERTICAL);
	my $sizerh = Wx::BoxSizer->new(Wx::wxHORIZONTAL);
	$sizerv->Add( $self->{search},    0, Wx::wxALL | Wx::wxEXPAND );
	$sizerv->Add( $self->{functions}, 1, Wx::wxALL | Wx::wxEXPAND );
	$sizerh->Add( $sizerv,            1, Wx::wxALL | Wx::wxEXPAND );

	# Fits panel layout
	$self->SetSizerAndFit($sizerh);
	$sizerh->SetSizeHints($self);

	# Grab the kill focus to prevent deselection
	Wx::Event::EVT_KILL_FOCUS(
		$self->{functions},
		sub {
			return;
		},
	);

	# Double-click a function name
	Wx::Event::EVT_LISTBOX_DCLICK(
		$self,
		$self->{functions},
		sub {
			$self->on_list_item_activated( $_[1] );
		}
	);

	# Handle key events
	Wx::Event::EVT_KEY_UP(
		$self->{functions},
		sub {
			my ( $this, $event ) = @_;
			if ( $event->GetKeyCode == Wx::WXK_RETURN ) {
				$self->on_list_item_activated($event);
			}
			$event->Skip(1);
		}
	);

	# Handle key events
	Wx::Event::EVT_CHAR(
		$self->{search},
		sub {
			my ( $this, $event ) = @_;

			my $code = $event->GetKeyCode;
			if ( $code == Wx::WXK_DOWN || $code == Wx::WXK_UP || $code == Wx::WXK_RETURN ) {

				# Up/Down and return keys focus on the functions lists
				$self->{functions}->SetFocus;
				my $selection = $self->{functions}->GetSelection;
				if ( $selection == -1 && $self->{functions}->GetCount > 0 ) {
					$selection = 0;
				}
				$self->{functions}->Select($selection);

			} elsif ( $code == Wx::WXK_ESCAPE ) {

				# Escape key clears search and returns focus
				# to the editor
				$self->{search}->SetValue('');
				my $current  = _CURRENT( $self->{main}->current );
				my $document = $current->document;
				if ($document) {
					$document->editor->SetFocus;
				}
			}

			$event->Skip(1);
		}
	);

	# React to user search
	Wx::Event::EVT_TEXT(
		$self,
		$self->{search},
		sub {
			$self->_update_functions_list;
		}
	);

	return $self;
}





######################################################################
# Padre::Wx::Role::View Methods

sub view_panel {
	return 'right';
}

sub view_label {
	shift->gettext_label;
}





#####################################################################
# Event Handlers

sub on_list_item_activated {
	my ( $self, $event ) = @_;

	# Which sub did they click
	my $subname = $self->{functions}->GetStringSelection;
	unless ( defined Params::Util::_STRING($subname) ) {
		return;
	}

	# Locate the function
	my $current  = _CURRENT( $self->{main}->current );
	my $document = $current->document or return;
	my $editor   = $document->editor;
	my ( $start, $end ) = Padre::Util::get_matches(
		$editor->GetText,
		$document->get_function_regex($subname),
		$editor->GetSelection, # Provides two params
	);
	unless ( defined $start ) {

		# Couldn't find it
		return;
	}

	# Move the selection to the sub location
	$editor->goto_pos_centerize($start);

	return;
}

# Sets the focus on the search field
sub focus_on_search {
	$_[0]->{search}->SetFocus;
}





######################################################################
# General Methods

sub gettext_label {
	Wx::gettext('Functions');
}

# Refresh the functions list
sub refresh {
	my ( $self, $current ) = @_;

	# Flush the list if there is no active document
	return unless $current;
	my $document  = $current->document;
	my $functions = $self->{functions};

	# Hide the widgets when no files are open
	if ($document) {
		$self->{search}->Show(1);
		$self->{functions}->Show(1);
	} else {
		$functions->Clear;
		$self->{search}->Hide;
		$self->{functions}->Hide;
		$self->{names} = [];
		return;
	}

	# Clear search when it is a different document
	if ( $self->{_document} && $document != $self->{_document} ) {
		$self->{search}->ChangeValue('');
	}
	$self->{_document} = $document;

	# Launch the background task
	require Padre::Task2::FunctionList;
	Padre::Task2::FunctionList->new(
		owner => $self,
		class => Scalar::Util::blessed($document),
		order => $self->{main}->config->main_functions_order,
		text  => $document->text_get,
		list  => undef,
	)->schedule;

	return 1;
}

# Set an updated method list from the task
sub set {
	my $self = shift;
	$self->{names} = shift;
	$self->render;
}

# Populate the functions list with search results
sub render {
	my $self      = shift;
	my $names     = $self->{names};
	my $search    = $self->{search};
	my $functions = $self->{functions};

	#quote the search string to make it safer
	my $string = $search->GetValue;
	if ( $string eq '' ) {
		$string = '.*';
	} else {
		$string = quotemeta $string;
	}

	# Show the components and populate the function list
	$search->Show;
	$functions->Show;
	$functions->Clear;
	foreach my $method ( reverse @$names ) {
		if ( $method =~ /$string/i ) {
			$functions->Insert( $method, 0 );
		}
	}

	return 1;
}

1;

# Copyright 2008-2010 The Padre development team as listed in Padre.pm.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.
