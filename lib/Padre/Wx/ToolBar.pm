package Padre::Wx::ToolBar;

use 5.008;
use strict;
use warnings;
use Padre::Wx         ();
use Padre::Wx::Editor ();

our $VERSION = '0.17';
our @ISA     = 'Wx::ToolBar';

sub new {
	my $class  = shift;
	my $parent = shift;
	my $self   = $class->SUPER::new( $parent, -1, Wx::wxDefaultPosition, Wx::wxDefaultSize,
								   Wx::wxNO_BORDER | Wx::wxTB_HORIZONTAL | Wx::wxTB_FLAT | Wx::wxTB_DOCKABLE, 5050, );

	# Automatically populate
	$self->AddTool(
		Wx::wxID_NEW, '',
		Padre::Wx::tango( 'actions', 'document-new.png' ),
		Wx::gettext('New File'),
	);
	Wx::Event::EVT_TOOL(
		$parent,
		Wx::wxID_NEW,
		sub { $_[0]->setup_editor; return; },
	);
	$self->AddTool(
		Wx::wxID_OPEN, '',
		Padre::Wx::tango( 'actions', 'document-open.png' ),
		Wx::gettext('Open File'),
	);
	$self->AddTool(
		Wx::wxID_SAVE, '',
		Padre::Wx::tango( 'actions', 'document-save.png' ),
		Wx::gettext('Save File'),
	);
	$self->AddTool(
		Wx::wxID_CLOSE, '',
		Padre::Wx::tango( 'emblems', 'emblem-unreadable.png' ),
		Wx::gettext('Close File'),
	);
	Wx::Event::EVT_TOOL(
		$parent,
		Wx::wxID_CLOSE,
		\&Padre::Wx::MainWindow::on_close,
	);
	$self->AddSeparator;




	# Undo/Redo Support
	$self->AddTool(
		Wx::wxID_UNDO, '',
		Padre::Wx::tango( 'actions', 'edit-undo.png' ),
		Wx::gettext('Undo'),
	);
	$self->AddTool(
		Wx::wxID_REDO, '',
		Padre::Wx::tango( 'actions', 'edit-redo.png' ),
		Wx::gettext('Redo'),
	);
	$self->AddSeparator;





	# Cut/Copy/Paste
	$self->AddTool(
		Wx::wxID_CUT, '',
		Padre::Wx::tango( 'actions', 'edit-cut.png' ),
		Wx::gettext('Cut'),
	);
	Wx::Event::EVT_TOOL(
		$parent,
		Wx::wxID_CUT,
		sub { \&Padre::Wx::Editor::text_cut_to_clipboard(@_) },
	);
	$self->AddTool(
		Wx::wxID_COPY,  '',
		Padre::Wx::tango( 'actions', 'edit-copy.png' ),
		Wx::gettext('Copy'),
	);
	Wx::Event::EVT_TOOL(
		$parent,
		Wx::wxID_COPY,
		sub { \&Padre::Wx::Editor::text_copy_to_clipboard(@_) },
	);
	$self->AddTool(
		Wx::wxID_PASTE, '',
		Padre::Wx::tango( 'actions', 'edit-paste.png' ),
		Wx::gettext('Paste'),
	);
	Wx::Event::EVT_TOOL(
		$parent,
		Wx::wxID_PASTE,
        sub { 
			my $editor = Padre->ide->wx->main_window->selected_editor or return;
			$editor->Paste;
		},
	);
	$self->AddTool(
		Wx::wxID_SELECTALL, '',
		Padre::Wx::tango( 'actions', 'edit-select-all.png' ),
		Wx::gettext('Select all'),
	);
	Wx::Event::EVT_TOOL(
		$parent,
		Wx::wxID_SELECTALL,
		sub { \&Padre::Wx::Editor::text_select_all(@_) },
	);

	return $self;
}

sub refresh {
	my $self    = shift;
	my $doc     = shift;
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
