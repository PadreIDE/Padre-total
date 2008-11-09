package Padre::Wx::ToolBar;

use 5.008;
use strict;
use warnings;

use Padre::Wx ();
use Padre::Wx::Editor ();
use Wx::Locale qw(:default);
use File::Spec::Functions qw(catfile);

our $VERSION = '0.16';
our @ISA     = 'Wx::ToolBar';

sub new {
	my $class  = shift;
	my $parent = shift;
	my $self   = $class->SUPER::new( $parent, -1, Wx::wxDefaultPosition, Wx::wxDefaultSize,
								   Wx::wxNO_BORDER | Wx::wxTB_HORIZONTAL | Wx::wxTB_FLAT | Wx::wxTB_DOCKABLE, 5050, );

	# Automatically populate
	$self->AddTool( Wx::wxID_NEW, '', Padre::Wx::tango( catfile( 'actions', 'document-new.png' ) ),
					gettext('New File') );
	$self->AddTool( Wx::wxID_OPEN, '', Padre::Wx::tango( catfile( 'actions', 'document-open.png' ) ),
					gettext('Open File') );
	$self->AddTool( Wx::wxID_SAVE, '', Padre::Wx::tango( catfile( 'actions', 'document-save.png' ) ),
					gettext('Save File') );
	$self->AddTool( Wx::wxID_CLOSE, '', Padre::Wx::tango( catfile( 'emblems', 'emblem-unreadable.png' ) ),
					gettext('Close File') );
	$self->AddSeparator;

	# TODO, how can we make sure these numbers are unique?
	#$self->AddTool( 1000, '', Padre::Wx::tango(catfile('actions', 'bookmark-new.png')), 'Bookmark' );
	#Wx::Event::EVT_TOOL($parent, 1000, sub { Padre::Wx::Dialog::Bookmarks->set_bookmark($_[0]) } );

	Wx::Event::EVT_TOOL( $parent, Wx::wxID_CLOSE, \&Padre::Wx::MainWindow::on_close );
	Wx::Event::EVT_TOOL( $parent, Wx::wxID_NEW, sub { $_[0]->setup_editor; return; } );

	$self->AddSeparator;

	$self->AddTool( Wx::wxID_UNDO, '', Padre::Wx::tango( catfile( 'actions', 'edit-undo.png' ) ), gettext('Undo') );
	$self->AddTool( Wx::wxID_REDO, '', Padre::Wx::tango( catfile( 'actions', 'edit-redo.png' ) ), gettext('Redo') );

	$self->AddSeparator;

	$self->AddTool( Wx::wxID_SELECTALL, '', Padre::Wx::tango( catfile( 'actions', 'edit-select-all.png' ) ),
					gettext('Select all') );
	$self->AddTool( Wx::wxID_COPY,  '', Padre::Wx::tango( catfile( 'actions', 'edit-copy.png' ) ),  gettext('Copy') );
	$self->AddTool( Wx::wxID_CUT,   '', Padre::Wx::tango( catfile( 'actions', 'edit-cut.png' ) ),   gettext('Cut') );
	$self->AddTool( Wx::wxID_PASTE, '', Padre::Wx::tango( catfile( 'actions', 'edit-paste.png' ) ), gettext('Paste') );

	Wx::Event::EVT_TOOL( $parent, Wx::wxID_SELECTALL, sub { \&Padre::Wx::Editor::text_select_all(@_) } );
	Wx::Event::EVT_TOOL( $parent, Wx::wxID_COPY, sub { \&Padre::Wx::Editor::text_copy_to_clipboard(@_) } );
	Wx::Event::EVT_TOOL( $parent, Wx::wxID_CUT, sub { \&Padre::Wx::Editor::text_cut_to_clipboard(@_) } );
	Wx::Event::EVT_TOOL( $parent, Wx::wxID_PASTE, sub { \&Padre::Wx::Editor::text_paste_from_clipboard(@_) } );

	return $self;
} ## end sub new

sub refresh {
	my $self = shift;
	my $doc  = shift;

	my $enabled = !!( $doc and $doc->is_modified );
	$self->EnableTool( Wx::wxID_SAVE, $enabled );

	$self->EnableTool( Wx::wxID_CLOSE, ( defined Padre::Documents->current ? 1 : 0 ) );
	return 1;
}

1;

# Copyright 2008 Gabor Szabo.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.
