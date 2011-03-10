package Padre::Wx::TodoList;

use 5.008005;
use strict;
use warnings;
use Scalar::Util          ();
use Params::Util          ();
use Padre::Role::Task     ();
use Padre::Wx::Role::View ();
use Padre::Wx::Role::Main ();
use Padre::Wx             ();

our $VERSION = '0.84';
our @ISA     = qw{
	Padre::Role::Task
	Padre::Wx::Role::View
	Padre::Wx::Role::Main
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

	# Temporary store for the todo list.
	$self->{model} = [];

	# Remember the last document we were looking at
	$self->{document} = '';

	# Create the search control
	$self->{search} = Wx::TextCtrl->new(
		$self,
		-1,
		'',
		Wx::wxDefaultPosition,
		Wx::wxDefaultSize,
		Wx::wxTE_PROCESS_ENTER | Wx::wxSIMPLE_BORDER,
	);

	# Create the Todo list
	$self->{list} = Wx::ListBox->new(
		$self,
		-1,
		Wx::wxDefaultPosition,
		Wx::wxDefaultSize,
		[],
		Wx::wxLB_SINGLE | Wx::wxBORDER_NONE
	);

	# Create a sizer
	my $sizer = Wx::BoxSizer->new(Wx::wxVERTICAL);
	$sizer->Add( $self->{search}, 0, Wx::wxALL | Wx::wxEXPAND );
	$sizer->Add( $self->{list},   1, Wx::wxALL | Wx::wxEXPAND );

	# Fits panel layout
	$self->SetSizerAndFit($sizer);
	$sizer->SetSizeHints($self);

	# Double-click a function name
	Wx::Event::EVT_LISTBOX_DCLICK(
		$self,
		$self->{list},
		sub {
			$_[0]->on_list_item_activated( $_[1] );
		}
	);

	# Handle double click on list
	# overwrite this handler to avoid stealing the focus back from the editor
	Wx::Event::EVT_LEFT_DCLICK(
		$self->{list},
		sub { return; }
	);

	# Handle key events
	Wx::Event::EVT_KEY_UP(
		$self->{list},
		sub {
			my ( $this, $event ) = @_;

			my $code = $event->GetKeyCode;
			if ( $code == Wx::WXK_RETURN ) {
				$self->on_list_item_activated($event);
			} elsif ( $code == Wx::WXK_ESCAPE ) {

				# Escape key clears search and returns focus
				# to the editor
				$self->{search}->SetValue('');
				my $editor = $self->current->editor;
				$editor->SetFocus if $editor;
			}

			$event->Skip(1);
			return;
		}
	);

	# Handle key events
	Wx::Event::EVT_CHAR(
		$self->{search},
		sub {
			my $this  = shift;
			my $event = shift;
			my $code  = $event->GetKeyCode;

			if ( $code == Wx::WXK_DOWN || $code == Wx::WXK_UP || $code == Wx::WXK_RETURN ) {

				# Up/Down and return keys focus on the functions lists
				$self->{list}->SetFocus;
				my $selection = $self->{list}->GetSelection;
				if ( $selection == -1 && $self->{list}->GetCount > 0 ) {
					$selection = 0;
				}
				$self->{list}->Select($selection);

			} elsif ( $code == Wx::WXK_ESCAPE ) {

				# Escape key clears search and returns the
				# focus to the editor.
				$self->{search}->SetValue('');
				my $editor = $self->current->editor;
				$editor->SetFocus if $editor;
			}

			$event->Skip(1);
		}
	);

	# React to user search
	Wx::Event::EVT_TEXT(
		$self,
		$self->{search},
		sub {
			$self->render;
		}
	);

	$main->add_refresh_listener($self);

	return $self;
}





######################################################################
# Padre::Wx::Role::View Methods

sub view_panel {
	return 'right';
}

sub view_label {
	shift->gettext_label(@_);
}

sub view_close {
	$_[0]->task_reset;
	$_[0]->main->show_todo(0);
}





#####################################################################
# Event Handlers

sub on_list_item_activated {
	my $self   = shift;
	my $event  = shift;
	my $editor = $self->current->editor or return;
	my $nth    = $self->{list}->GetSelection;
	my $todo   = $self->{model}->[$nth] or return;

	# Move the selection to where we last saw it
	$editor->goto_pos_centerize( $todo->{pos} );
	$editor->SetFocus;

	return;
}





######################################################################
# General Methods

sub gettext_label {
	Wx::gettext('To-do');
}

# Sets the focus on the search field
sub focus_on_search {
	$_[0]->{search}->SetFocus;
}

sub refresh {
	my $self     = shift;
	my $current  = shift or return;
	my $document = $current->document;
	my $search   = $self->{search};
	my $list     = $self->{list};

	# Flush and hide the list if there is no active document
	unless ($document) {
		my $lock = $self->main->lock('UPDATE');
		$search->Hide;
		$list->Hide;
		$list->Clear;
		$self->{model}    = [];
		$self->{document} = '';
		return;
	}

	# Ensure the widget is visible
	$search->Show(1);
	$list->Show(1);

	# Clear search when it is a different document
	my $id = Scalar::Util::refaddr($document);
	if ( $id ne $self->{document} ) {
		$search->ChangeValue('');
		$self->{document} = $id;
	}

	# Unlike the Function List widget we copied to make this,
	# don't bother with a background task, since this is much quicker.
	my $regexp = $current->config->todo_regexp;
	my $text   = $document->text_get;
	my @items  = ();
	eval {
		while ( $text =~ /$regexp/gim )
		{
			push @items, { text => $1 || '<no text>', 'pos' => pos($text) };
		}
	};
	$self->main->error( sprintf( Wx::gettext('%s in TODO regex, check your config.'), $@ ) ) if $@;
	while ( $text =~ /#\s*(Ticket #\d+.*?)$/gim ) {
		push @items, { text => $1, 'pos' => pos($text) };
	}

	if ( @items == 0 ) {
		$list->Clear;
		$self->{model} = [];
		return;
	}

	# Update the model and rerender
	$self->{model} = \@items;
	$self->render;
}

# Populate the list with search results
sub render {
	my $self   = shift;
	my $model  = $self->{model};
	my $search = $self->{search};
	my $list   = $self->{list};

	# Quote the search string to make it safer
	my $string = $search->GetValue;
	if ( $string eq '' ) {
		$string = '.*';
	} else {
		$string = quotemeta $string;
	}

	# Show the components and populate the function list
	SCOPE: {
		my $lock = $self->main->lock('UPDATE');
		$search->Show(1);
		$list->Show(1);
		$list->Clear;
		foreach my $todo ( reverse @$model ) {
			my $text = $todo->{text};
			if ( $text =~ /$string/i ) {
				$list->Insert( $text, 0 );
			}
		}
	}

	return 1;
}

1;

# Copyright 2008-2011 The Padre development team as listed in Padre.pm.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.
