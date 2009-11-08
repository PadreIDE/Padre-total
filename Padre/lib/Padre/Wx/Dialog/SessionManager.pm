package Padre::Wx::Dialog::SessionManager;

# This file is part of Padre, the Perl ide.

use 5.008;
use strict;
use warnings;
use POSIX qw{ strftime };
use Padre::Wx       ();
use Padre::Wx::Icon ();

our $VERSION = '0.50';
our @ISA     = 'Wx::Dialog';

use Class::XSAccessor accessors => {
	_butdelete   => '_butdelete',   # delete button
	_butopen     => '_butopen',     # open button
	_currow      => '_currow',      # current list row number
	_curname     => '_curname',     # name of current session selected
	_list        => '_list',        # list on the left of the pane
	_sortcolumn  => '_sortcolumn',  # column used for list sorting
	_sortreverse => '_sortreverse', # list sorting is reversed
	_vbox        => '_vbox',        # the window vbox sizer
};

# -- constructor

sub new {
	my ( $class, $parent ) = @_;

	# create object
	my $self = $class->SUPER::new(
		$parent,
		-1,
		Wx::gettext('Session Manager'),
		Wx::wxDefaultPosition,
		Wx::Size->new( 480, 300 ),
		Wx::wxDEFAULT_FRAME_STYLE | Wx::wxTAB_TRAVERSAL,
	);

	$self->SetIcon(Padre::Wx::Icon::PADRE);

	# create dialog
	$self->_create;

	return $self;
}

# -- public methods

sub show {
	my $self = shift;

	$self->_refresh_list;
	$self->_select_first_item;
	$self->Show;
}

# -- gui handlers

#
# $self->_on_butclose_clicked;
#
# handler called when the close button has been clicked.
#
sub _on_butclose_clicked {
	my $self = shift;
	$self->Destroy;
}

#
# $self->_on_butdelete_clicked;
#
# handler called when the delete button has been clicked.
#
sub _on_butdelete_clicked {
	my $self    = shift;
	my $current = $self->_current_session;

	# remove session: files, then session itself
	Padre::DB->begin;
	Padre::DB::SessionFile->delete( 'where session = ?', $current->id );
	$current->delete;
	Padre::DB->commit;

	# update gui
	$self->_refresh_list;
	$self->_select_first_item;
	$self->_update_buttons_state;
}

#
# $self->_on_butopen_clicked;
#
# handler called when the open button has been clicked.
#
sub _on_butopen_clicked {
	my $self = shift;

	# prevents crash if user double-clicks on list
	# item and tries to click buttons
	$self->_butdelete->Disable;
	$self->_butopen->Disable;

	# close all open documents
	my $main = $self->GetParent;
	$main->open_session( $self->_current_session, $self->{autosave}->GetValue );
	$self->Destroy();
}

#
# $self->_on_list_col_click;
#
# handler called when a column has been clicked, to reorder the list.
#
sub _on_list_col_click {
	my ( $self, $event ) = @_;
	my $col = $event->GetColumn;

	my $prevcol  = $self->_sortcolumn  || 0;
	my $reversed = $self->_sortreverse || 0;
	$reversed = $col == $prevcol ? !$reversed : 0;
	$self->_sortcolumn($col);
	$self->_sortreverse($reversed);
	$self->_refresh_list( $col, $reversed );
}

#
# $self->_on_list_item_selected( $event );
#
# handler called when a list item has been selected. it will in turn update
# the buttons state.
#
# $event is a Wx::ListEvent.
#
sub _on_list_item_selected {
	my ( $self, $event ) = @_;

	my $name = $event->GetLabel;
	$self->_curname($name);             # storing selected session
	$self->_currow( $event->GetIndex ); # storing selected row

	# update buttons
	$self->_update_buttons_state;
}

#
# $self->_on_list_item_activated( $event );
#
# handler called when a list item has been double clicked. it will automatically open
# the selected session
#
# $event is a Wx::ListEvent.
#
sub _on_list_item_activated {
	my ( $self, $event ) = @_;

	$self->_on_list_item_selected($event);
	$self->_on_butopen_clicked();
}

# -- private methods

#
# $self->_create;
#
# create the dialog itself. it will have a list with all found sessions, and
# some buttons to manage them.
#
# no params, no return values.
#
sub _create {
	my $self = shift;

	# create vertical box that will host all controls
	my $vbox = Wx::BoxSizer->new(Wx::wxVERTICAL);
	$self->SetSizer($vbox);
	$self->CenterOnParent;

	#$self->SetMinSize( [ 640, 480 ] );
	$self->_vbox($vbox);

	$self->_create_list;
	$self->_create_options;
	$self->_create_buttons;
	$self->_list->SetFocus;
}

#
# $dialog->_create_list;
#
# create the sessions list. it will hold a list of available sessions, along
# with their description & last update.
#
# no params. no return values.
#
sub _create_list {
	my $self = shift;
	my $vbox = $self->_vbox;

	# title label
	my $label = Wx::StaticText->new(
		$self, -1,
		Wx::gettext('List of sessions')
	);
	$vbox->Add( $label, 0, Wx::wxALL, 5 );

	# create list
	my $list = Wx::ListView->new(
		$self,
		-1,
		Wx::wxDefaultPosition,
		Wx::wxDefaultSize,
		Wx::wxLC_REPORT | Wx::wxLC_SINGLE_SEL,
	);
	$list->InsertColumn( 0, Wx::gettext('Name') );
	$list->InsertColumn( 1, Wx::gettext('Description') );
	$list->InsertColumn( 2, Wx::gettext('Last update') );
	$self->_list($list);

	# install event handler
	Wx::Event::EVT_LIST_ITEM_SELECTED( $self, $list, \&_on_list_item_selected );
	Wx::Event::EVT_LIST_ITEM_ACTIVATED( $self, $list, \&_on_list_item_activated );
	Wx::Event::EVT_LIST_COL_CLICK( $self, $list, \&_on_list_col_click );

	# pack the list
	$vbox->Add( $list, 1, Wx::wxALL | Wx::wxEXPAND, 5 );
}

#
# $dialog->_create_options;
#
# create the options
#
# no params. no return values.
#
sub _create_options {
	my $self = shift;

	# the hbox
	my $hbox = Wx::BoxSizer->new(Wx::wxHORIZONTAL);
	$self->_vbox->Add( $hbox, 0, Wx::wxALL | Wx::wxEXPAND, 5 );

	# CheckBox
	$self->{autosave} = Wx::CheckBox->new(
		$self,
		-1,
		Wx::gettext('Save session automatically'),
	);

	#	Wx::Event::EVT_CHECKBOX(
	#		$self,
	#		$self->{autosave},
	#		sub {
	#			$_[0]->{find_text}->SetFocus;
	#		}
	#	);
	$hbox->Add( $self->{autosave}, 0, Wx::wxALL, 5 );
}

#
# $dialog->_create_buttons;
#
# create the buttons pane.
#
# no params. no return values.
#
sub _create_buttons {
	my $self = shift;

	# the hbox
	my $hbox = Wx::BoxSizer->new(Wx::wxHORIZONTAL);
	$self->_vbox->Add( $hbox, 0, Wx::wxALL | Wx::wxEXPAND, 5 );

	# the buttons
	my $bo = Wx::Button->new( $self, -1,              Wx::gettext('Open') );
	my $bd = Wx::Button->new( $self, -1,              Wx::gettext('Delete') );
	my $bc = Wx::Button->new( $self, Wx::wxID_CANCEL, Wx::gettext('Close') );
	$self->_butopen($bo);
	$self->_butdelete($bd);
	Wx::Event::EVT_BUTTON( $self, $bo, \&_on_butopen_clicked );
	Wx::Event::EVT_BUTTON( $self, $bd, \&_on_butdelete_clicked );
	Wx::Event::EVT_BUTTON( $self, $bc, \&_on_butclose_clicked );
	$hbox->Add( $bo, 0, Wx::wxALL, 5 );
	$hbox->Add( $bd, 0, Wx::wxALL, 5 );
	$hbox->AddStretchSpacer;
	$hbox->Add( $bc, 0, Wx::wxALL, 5 );
}

#
# my $session = $self->_current_session;
#
# return the padre::db::session object corresponding to currently selected line
# in the list. return undef if no object selected.
#
sub _current_session {
	my $self = shift;
	my ($current) = Padre::DB::Session->select(
		'where name = ?',
		$self->_curname
	);
	return $current;
}

#
# $dialog->_refresh_list($column, $reverse);
#
# refresh list of sessions. list is sorted according to $column (default to
# first column), and may be reversed (default to no).
#
sub _refresh_list {
	my ( $self, $column, $reverse ) = @_;

	# default sorting
	$column  ||= 0;
	$reverse ||= 0;
	my @fields = qw{ name description last_update }; # db fields of table session

	# get list of sessions, sorted.
	my $sort = "ORDER BY $fields[$column]";
	$sort .= ' DESC' if $reverse;
	my @sessions = Padre::DB::Session->select($sort);

	# clear list & fill it again
	my $list = $self->_list;
	$list->DeleteAllItems;
	foreach my $session ( reverse @sessions ) {
		my $name   = $session->name;
		my $descr  = $session->description;
		my $update = strftime( '%F %T', localtime( $session->last_update ) );

		# inserting the session in the list
		my $item = Wx::ListItem->new;
		$item->SetId(0);
		$item->SetColumn(0);
		$item->SetText($name);
		my $idx = $list->InsertItem($item);
		$list->SetItem( $idx, 1, $descr );
		$list->SetItem( $idx, 2, $update );
	}

	# auto-resize columns
	my $flag =
		$list->GetItemCount
		? Wx::wxLIST_AUTOSIZE
		: Wx::wxLIST_AUTOSIZE_USEHEADER;
	$list->SetColumnWidth( $_, $flag ) for 0 .. 2;

	# making sure the list can show all columns
	my $width = 15; # taking vertical scrollbar into account
	$width += $list->GetColumnWidth($_) for 0 .. 2;
	$list->SetMinSize( [ $width, -1 ] );
}

#
# $self->_select_first_item;
#
# select first item in the list, or none if there are none. in that case,
# update the current row and name selection to undef.
#
sub _select_first_item {
	my ($self) = @_;

	# select first item in the list
	my $list = $self->_list;

	if ( $list->GetItemCount ) {
		my $item = $list->GetItem(0);
		$item->SetState(Wx::wxLIST_STATE_SELECTED);
		$list->SetItem($item);
	} else {

		# remove current selection
		$self->_currow(undef);
		$self->_curname(undef);
	}
}

#
# $self->_update_buttons_state;
#
# update state of delete and open buttons: they should not be clickable if no
# session is selected.
#
sub _update_buttons_state {
	my ($self) = @_;

	my $method = defined( $self->_currow ) ? 'Enable' : 'Disable';
	$self->_butdelete->$method;
	$self->_butopen->$method;
}

1;

__END__


=head1 NAME

Padre::Wx::Dialog::SessionManager - Session manager dialog for Padre



=head1 DESCRIPTION

Padre supports sessions, that is, a bunch of files opened. But we need to
provide a way to manage those sessions: listing, removing them, etc. This
module implements this task as a dialog for Padre.



=head1 PUBLIC API

=head2 Constructor

=over 4

=item * my $dialog = PWD::SM->new( $parent )

Create and return a new Wx dialog listing all the sessions. It needs a
C<$parent> window (usually padre's main window).


=back



=head2 Public methods

=over 4

=item * $dialog->show;

Request the session manager dialog to be shown. It will be refreshed first with
a current list of sessions.


=back



=head1 COPYRIGHT & LICENSE

Copyright 2008-2009 The Padre development team as listed in Padre.pm.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl 5 itself.


=cut


# Copyright 2008-2009 The Padre development team as listed in Padre.pm.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.
