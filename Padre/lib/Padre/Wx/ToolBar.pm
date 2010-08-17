package Padre::Wx::ToolBar;

use 5.008;
use strict;
use warnings;
use Padre::Current    ();
use Padre::Wx         ();
use Padre::Wx::Icon   ();
use Padre::Wx::Editor ();
use Padre::Constant   ();

our $VERSION = '0.69';
our @ISA     = 'Wx::ToolBar';

# NOTE: Something is wrong with dockable toolbars on Windows
#       so disable them for now.
use constant DOCKABLE => !Padre::Constant::WXWIN32;

sub new {
	my $class = shift;
	my $main  = shift;

	my $config = $main->config;

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

	$self->{main} = $main;

	# Default icon size is 16x15 for Wx, to use the 16x16 GPL
	# icon sets we need to be SLIGHTLY bigger.
	$self->SetToolBitmapSize( Wx::Size->new( 16, 16 ) );

	# toolbar id sequence generator
	# Toolbar likes only unique values. Do otherwise on your own risk.
	$self->{next_id} = 10000;

	# This is a very first step to create a customizable toolbar.
	# Actually there is no dialog for editing this parameter, if
	# anyone wants to change the toolbar, it needs to be done manuelly
	# within config.yml.

	foreach my $item ( split( /\;/, $config->main_toolbar_items ) ) {

		if ( $item eq '|' ) {
			$self->AddSeparator;
			next;
		}

		if ( $item =~ /^(.+?)\((.*)\)$/ ) {
			my $action = $1;
			$self->add_tool_item(
				action => $action,
				args   => split( /\,/, $2 ),
			);
			next;
		}

		if ( $item =~ /^(.+?)$/ ) {
			my $action = $1;
			$self->add_tool_item(
				action => $action,
			);
			next;
		}

		warn( 'Unknown toolbar item: ' . $item );

	}

	return $self;
}

#
# Add a tool item to the toolbar re-using Padre menu action name
#
sub add_tool_item {
	my ( $self, %args ) = @_;

	my $actions = Padre::ide->actions;

	my $action = $actions->{ $args{action} };
	unless ($action) {
		warn("No action called $args{action}\n");
		return;
	}
	my $icon = $action->toolbar_icon;
	unless ($icon) {
		warn("Action $args{action} does not have an icon defined\n");
		return;
	}

	# the ID code should be unique otherwise it can break the event system.
	# If set to -1 such as in the default call below, it will override
	# any previous item with that id.
	my $id = $self->{next_id}++;

	# Store ID on item list
	$self->{item_list} = {}
		if ( !defined( $self->{item_list} ) )
		or ( ref( $self->{item_list} ) ne 'HASH' );
	$self->{item_list}->{$id} = $action;

	# Create the tool
	$self->AddTool(
		$id, '',
		Padre::Wx::Icon::find($icon),
		$action->label_text,
	);

	# Add the optional event hook
	Wx::Event::EVT_TOOL(
		$self->GetParent,
		$id,
		$action->menu_event,
	);

	return $id;
}

sub refresh {
	my $self      = shift;
	my $current   = Padre::Current::_CURRENT(@_);
	my $editor    = $current->editor;
	my $document  = $current->document;
	my $text      = $current->text;
	my $selection = ( defined $text and $text ne '' ) ? 1 : 0;

	foreach my $item ( keys( %{ $self->{item_list} } ) ) {

		my $action = $self->{item_list}->{$item};

		my $enabled = 1; # Set default

		$enabled = 0
			if $action->{need_editor} and ( !$editor );

		$enabled = 0
			if $action->{need_file}
				and (  ( !defined($document) )
					or ( !defined( $document->{file} ) )
					or ( !defined( $document->file->filename ) ) );

		$enabled = 0
			if $action->{need_modified}
				and defined($document)
				and ( !$document->is_modified );

		$enabled = 0
			if $action->{need_selection} and ( !$selection );

		$enabled = 0
			if defined( $action->{need} )
				and ( ref( $action->{need} ) eq 'CODE' )
				and (
					!&{ $action->{need} }(
						editor   => $editor,
						document => $document,
						main     => $self->{main},
						config   => $self->{main}->config,
					)
				);

		$self->EnableTool( $item, $enabled );

	}

	return;
}

1;

# Copyright 2008-2010 The Padre development team as listed in Padre.pm.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.
