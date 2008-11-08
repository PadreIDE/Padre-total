package Padre::Wx::ToolBar;

use 5.008;
use strict;
use warnings;

use Wx qw(:dnd wxTheClipboard);
use Wx::DND;
use Padre::Wx ();
use Wx::Locale qw(:default);
use File::Spec::Functions qw(catfile);

our $VERSION = '0.15';
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

	Wx::Event::EVT_TOOL(
		$parent,
		Wx::wxID_SELECTALL,
		sub {
			my $win = shift;
			my $evt = shift;

			my $id = $win->{notebook}->GetSelection;
			return if $id == -1;
			$win->{notebook}->GetPage($id)->SelectAll;
			return;
		}
	);

	Wx::Event::EVT_TOOL(
		$parent,
		Wx::wxID_COPY,
		sub {
			my $win = shift;
			my $evt = shift;

			my $id = $win->{notebook}->GetSelection;
			return if $id == -1;
			wxTheClipboard->Open;

			my $txt = $win->{notebook}->GetPage($id)->GetSelectedText;
			if ( defined($txt) ) {
				wxTheClipboard->SetData( Wx::TextDataObject->new($txt) );
			}

			wxTheClipboard->Close;
			return;
		},
	);
	Wx::Event::EVT_TOOL(
		$parent,
		Wx::wxID_CUT,
		sub {
			my $win = shift;
			my $evt = shift;

			my $id = $win->{notebook}->GetSelection;
			return if $id == -1;
			wxTheClipboard->Open;

			my $txt = $win->{notebook}->GetPage($id)->GetSelectedText;
			if ( defined($txt) ) {
				wxTheClipboard->SetData( Wx::TextDataObject->new($txt) );
				$win->{notebook}->GetPage($id)->ReplaceSelection('');
			}

			wxTheClipboard->Close;
			return;
		},
	);
	Wx::Event::EVT_TOOL(
		$parent,
		Wx::wxID_PASTE,
		sub {
			my $win = shift;
			my $evt = shift;
			my $id  = $win->{notebook}->GetSelection;
			return if $id == -1;
			wxTheClipboard->Open;
			my $text   = '';
			my $length = 0;
			if ( wxTheClipboard->IsSupported(wxDF_TEXT) ) {
				my $data = Wx::TextDataObject->new;
				my $ok   = wxTheClipboard->GetData($data);
				if ($ok) {
					$text   = $data->GetText;
					$length = $data->GetTextLength;
				}
				else {
					$text   = '';
                    $length = 1;
				}
			}
			my $pos = $win->{notebook}->GetPage($id)->GetCurrentPos;
			$win->{notebook}->GetPage($id)->InsertText( $pos, $text );
			$win->{notebook}->GetPage($id)->GotoPos( $pos + $length - 1 );
			wxTheClipboard->Close;
			return;
		},
	);

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
