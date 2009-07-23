package Padre::Wx::ToolBar;

use 5.008;
use strict;
use warnings;
use Padre::Current qw{_CURRENT};
use Padre::Wx         ();
use Padre::Wx::Icon   ();
use Padre::Wx::Editor ();

our $VERSION = '0.40';
our @ISA     = 'Wx::ToolBar';

# NOTE: Something is wrong with dockable toolbars on Windows
#       so disable them for now.
use constant DOCKABLE => !Padre::Constant::WXWIN32;

sub new {
	my $class = shift;
	my $main  = shift;

	# Prepare the style
	my $style = Wx::wxTB_HORIZONTAL | Wx::wxTB_FLAT | Wx::wxTB_NODIVIDER | Wx::wxBORDER_NONE;
	if ( DOCKABLE and not $main->config->main_lockinterface ) {
		$style = $style | Wx::wxTB_DOCKABLE;
	}

	# Create the parent Wx object
	my $self = $class->SUPER::new(
		$main, -1,
		Wx::wxDefaultPosition,
		Wx::wxDefaultSize,
		$style,
		5050,
	);
	
	# Default icon size is 16x15 for Wx, to use the 16x16 GPL
	# icon sets we need to be SLIGHTLY bigger.
	$self->SetToolBitmapSize( Wx::Size->new( 16, 16 ) );

	# toolbar id sequence generater
	$self->{next_id} = 10000;

	# Populate the toolbar
	$self->add_tool_item(
		name  => 'toolbar.document_new',
		icon  => 'actions/document-new',
		label => Wx::gettext('New File'),
		toolbar_event => sub {
			$_[0]->on_new;
		},
	);

	$self->add_tool_item(
		name  => 'toolbar.document_open',
		icon  => 'actions/document-open',
		label => Wx::gettext('Open File'),
		toolbar_event => sub {
		},
	);

	$self->add_tool_item(
		name  => 'toolbar.document_save',
		icon  => 'actions/document-save',
		label => Wx::gettext('Save File'),
		toolbar_event => sub {
		},
	);

	$self->add_tool_item(
		name  => 'toolbar.document_save_as',
		icon  => 'actions/document-save-as',
		label => Wx::gettext('Save as...'),
		toolbar_event => sub {
		},
	);

	$self->add_tool_item(
		name  => 'toolbar.save_all',
		icon  => 'actions/stock_data-save',
		label => Wx::gettext('Save All'),
		toolbar_event => sub {
			Padre::Wx::Main::on_save_all(@_);
		},
	);

	$self->add_tool_item(
		name  => 'toolbar.close',
		icon  => 'actions/x-document-close',
		label => Wx::gettext('Close File'),
		toolbar_event => sub {
			$_[0]->on_close( $_[1] );
		},
	);

	# Undo/Redo Support
	$self->AddSeparator;

	$self->add_tool_item(
		name  => 'toolbar.undo',
		icon  => 'actions/edit-undo',
		label => Wx::gettext('Undo'),
		toolbar_event => sub {
		},
	);

	$self->add_tool_item(
		name  => 'toolbar.redo',
		icon  => 'actions/edit-redo',
		label => Wx::gettext('Redo'),
		toolbar_event => sub {
		},
	);

	# Cut/Copy/Paste
	$self->AddSeparator;

	$self->add_tool_item(
		name  => 'toolbar.cut',
		icon  => 'actions/edit-cut',
		label => Wx::gettext('Cut'),
		toolbar_event => sub {
			Wx::Window::FindFocus->Cut;
		},
	);

	$self->add_tool_item(
		name  => 'toolbar.copy',
		icon  => 'actions/edit-copy',
		label => Wx::gettext('Copy'),
		toolbar_event => sub {
			Wx::Window::FindFocus->Copy;
		},
	);

	$self->add_tool_item(
		name  => 'toolbar.paste',
		icon  => 'actions/edit-paste',
		label => Wx::gettext('Paste'),
		toolbar_event => sub {
			my $editor = Padre::Current->editor or return;
			$editor->Paste;
		},
	);

	$self->add_tool_item(
		name  => 'toolbar.select_all',
		icon  => 'actions/edit-select-all',
		label => Wx::gettext('Select All'),
		toolbar_event => sub {
			Wx::Window::FindFocus->SelectAll();
		},
	);

	# find and replace
	$self->AddSeparator;

	$self->add_tool_item(
		name  => 'toolbar.find',
		icon  => 'actions/edit-find',
		label => Wx::gettext('Find'),
		toolbar_event => sub {
		}
	);

	$self->add_tool_item(
		name  => 'toolbar.find_replace',
		icon  => 'actions/edit-find-replace',
		label => Wx::gettext('Find and Replace'),
		toolbar_event => sub {
		}
	);

	# Document Transforms
	$self->AddSeparator;

	$self->add_tool_item(
		name  => 'toolbar.toggle_comments',
		icon  => 'actions/toggle-comments',
		label => Wx::gettext('Toggle Comments'),
		toolbar_event => sub {
			Padre::Wx::Main::on_comment_toggle_block(@_);
		},
	);

	$self->AddSeparator;

	$self->add_tool_item(
		name  => 'toolbar.document_stats',
		icon  => 'actions/document-properties',
		label => Wx::gettext('Document Stats'),
		toolbar_event => sub {
			Padre::Wx::Main::on_doc_stats(@_);
		},
	);

	return $self;
}

#
# Add a tool item to the toolbar from a Padre action
#
sub add_tool_item {
	my $self = shift;

	my $actions = Padre::ide->actions;
	my $action = Padre::Action->new(@_);
	my $shortcut = $action->shortcut;
	$self->_add_tool(
		id    => $action->id,
		icon  => $action->icon,
		short => $action->label . ($shortcut ? ("\t" . $shortcut) : ''),
		event => $action->toolbar_event,
	);
	
	if($actions->{$action->name}) {
		warn "Found a duplicate action '" . $action->name . "'\n";
	}
	if($shortcut) {
		foreach my $action_name (keys %{$actions}) {
			my $a = $actions->{$action_name};
			if($a->shortcut eq $shortcut) {
				warn "Found a duplicate shortcut '" . $action->shortcut . 
					"' with " . $a->name . " for '" . $action->name . "'\n";
				last;
			}
		}
	}
	$actions->{$action->name} = $action;

	return;
}

sub refresh {
	my $self      = shift;
	my $current   = _CURRENT(@_);
	my $editor    = $current->editor;
	my $document  = $current->document;
	my $text      = $current->text;
	my $selection = ( defined $text and $text ne '' ) ? 1 : 0;

	$self->EnableTool( Wx::wxID_SAVE, ( $document and $document->is_modified ? 1 : 0 ) );
	$self->EnableTool( Wx::wxID_SAVEAS, ($document) );

	# trying out the Comment Code method here
	$self->EnableTool( 1000, ($document) ); # Save All

	$self->EnableTool( Wx::wxID_CLOSE, ( $editor ? 1 : 0 ) );
	$self->EnableTool( Wx::wxID_UNDO,  ( $editor and $editor->CanUndo ) );
	$self->EnableTool( Wx::wxID_REDO,  ( $editor and $editor->CanRedo ) );
	$self->EnableTool( Wx::wxID_CUT,   ($selection) );
	$self->EnableTool( Wx::wxID_COPY,  ($selection) );
	$self->EnableTool( Wx::wxID_PASTE, ( $editor and $editor->CanPaste ) );
	$self->EnableTool( Wx::wxID_SELECTALL, ( $editor ? 1 : 0 ) );
	$self->EnableTool( Wx::wxID_FIND,      ( $editor ? 1 : 0 ) );
	$self->EnableTool( Wx::wxID_REPLACE,   ( $editor ? 1 : 0 ) );
	$self->EnableTool( 999,  ( $document ? 1 : 0 ) );
	$self->EnableTool( 1001, ( $editor   ? 1 : 0 ) );

	return;
}

#####################################################################
# Toolbar 2.0

sub _add_tool {
	my $self  = shift;
	my %param = @_;

	# the ID code should be unique otherwise it can break the event system. 
	# If set to -1 such as in the default call below, it will override 
	# any previous item with that id.
	my $id = $self->{next_id}++;

	# Create the tool
	$self->AddTool(
		$id, '',
		Padre::Wx::Icon::find( $param{icon} ),
		$param{short},
	);

	# Add the optional event hook
	if ( defined $param{event} ) {
		Wx::Event::EVT_TOOL(
			$self->GetParent,
			$id,
			$param{event},
		);
	}

	return;
}

1;

# Copyright 2008-2009 The Padre development team as listed in Padre.pm.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.
