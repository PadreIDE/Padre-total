package Padre::Wx::Directory;

use 5.008;
use strict;
use warnings;
use Padre::Role::Task                ();
use Padre::Wx::Role::View            ();
use Padre::Wx::Role::Main            ();
use Padre::Wx::Directory::TreeCtrl   ();
use Padre::Wx::Directory::SearchCtrl ();
use Padre::Wx                        ();

our $VERSION = '0.64';
our @ISA     = qw{
	Padre::Role::Task
	Padre::Wx::Role::View
	Padre::Wx::Role::Main
	Wx::Panel
};

use Class::XSAccessor {
	getters => {
		tree   => 'tree',
		search => 'search',
	},
};





######################################################################
# Constructor

# Creates the Directory Left Panel with a Search field
# and the Directory Browser
sub new {
	my $class = shift;
	my $main  = shift;

	# Create the parent panel, which will contain the search and tree
	my $self = $class->SUPER::new(
		$main->directory_panel,
		-1,
		Wx::wxDefaultPosition,
		Wx::wxDefaultSize,
	);

	# State storage
	$self->{files} = [ ];

	# Creates the Search Field and the Directory Browser
	$self->{tree}   = Padre::Wx::Directory::TreeCtrl->new($self);
	$self->{search} = Padre::Wx::Directory::SearchCtrl->new($self);

	# Fill the panel
	my $sizerv = Wx::BoxSizer->new(Wx::wxVERTICAL);
	my $sizerh = Wx::BoxSizer->new(Wx::wxHORIZONTAL);
	$sizerv->Add( $self->search, 0, Wx::wxALL | Wx::wxEXPAND, 0 );
	$sizerv->Add( $self->tree,   1, Wx::wxALL | Wx::wxEXPAND, 0 );
	$sizerh->Add( $sizerv,       1, Wx::wxALL | Wx::wxEXPAND, 0 );

	# Fits panel layout
	$self->SetSizerAndFit($sizerh);
	$sizerh->SetSizeHints($self);

	return $self;
}





######################################################################
# Padre::Wx::Role::View Methods

sub view_panel {
	shift->side(@_);
}

sub view_label {
	shift->gettext_label(@_);
}

sub view_close {
	shift->main->show_directory(0);
}





######################################################################
# General Methods

# The parent panel
sub panel {
	$_[0]->GetParent;
}

# The current directory
sub root {
	my $self    = shift;
	my $current = $self->current;
	my $project = $current->project;
	if ( $project ) {
		return $project->root;
	} else {
		return $current->config->default_projects_directory;
	}
}

# Returns the window label
sub gettext_label {
	Wx::gettext('Project');
}

# Updates the gui, so each compoment can update itself
# according to the new state
sub clear {
	my $self = shift;
	my $tree = $self->tree;
	my $root = $tree->GetRootItem;
	$tree->DeleteChildren($root);
	return;
}

# Updates the gui if needed, calling Searcher and Browser respectives
# refresh function.
# Called outside Directory.pm, on directory browser focus and item dragging
sub refresh {
	my $self = shift;

	# NOTE: Without a file open, Padre does not consider itself to
	# have a "current project". We should probably try to find a way
	# to correct this in future.
	my $project = $self->current->project;
	my @options = $project
		? ( project => $project    )
		: ( root    => $self->root );

	# Trigger the second-generation refresh task
	$self->task_request(
		task      => 'Padre::Wx::Directory::Task',
		callback  => 'refresh_response',
		recursive => 1,
		@options,
	);

	return 1;
}

sub refresh_response {
	my $self = shift;
	my $task = shift;
	$self->{files} = $task->{model};
	$self->render;
}

# This is a primitive first attempt to get familiar with the tree API
sub render {
	my $self = shift;
	my $tree = $self->tree;
	my $lock = $self->main->lock('UPDATE');

	# Flush the old state
	$self->clear;

	# Fill the new tree
	my @stack = ();
	my @files = @{$self->{files}};
	while ( @files ) {
		my $path  = shift @files;
		my $image = $path->type ? 'folder' : 'package';
		while ( @stack ) {
			# If we are not the child of the deepest element in
			# the stack, move up a level and try again
			last if $tree->GetPlData($stack[-1])->is_parent($path);
			pop @stack;
		}

		# If there is anything left on the stack it is our parent
		my $parent = $stack[-1] || $tree->GetRootItem;

		# Add the next item to that parent
		my $item = $tree->AppendItem(
			$parent,                      # Parent node
			$path->name,                  # Label
			$tree->{images}->{$image},    # Icon
			-1,                           # Wx Identifier
			Wx::TreeItemData->new($path), # Embedded data
		);

		# If it is a folder, it goes onto the stack
		if ( $path->type == 1 ) {
			push @stack, $item;
			$tree->Expand($item);
		}
	}

	return 1;
}





######################################################################
# Panel Migration Support

# What side of the application are we on
sub side {
	my $self  = shift;
	my $panel = $self->GetParent;
	if ( $panel->isa('Padre::Wx::Left') ) {
		return 'left';
	}
	if ( $panel->isa('Padre::Wx::Right') ) {
		return 'right';
	}
	die "Bad parent panel";
}

# Moves the panel to the other side
sub move {
	my $self   = shift;
	my $config = $self->main->config;
	my $side   = $config->main_directory_panel;
	if ( $side eq 'left' ) {
		$config->apply( main_directory_panel => 'right' );
	} elsif ( $side eq 'right' ) {
		$config->apply( main_directory_panel => 'left' );
	} else {
		die "Bad main_directory_panel setting '$side'";
	}
}

1;

# Copyright 2008-2010 The Padre development team as listed in Padre.pm.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.
