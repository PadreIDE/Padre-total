package Padre::Wx::FindInFiles;

# Class for the output window at the bottom of Padre that is used to display
# results from Find in Files searches.

use 5.008;
use strict;
use warnings;
use File::Basename        ();
use File::Spec            ();
use Params::Util          ();
use Padre::Role::Task     ();
use Padre::Wx::Role::View ();
use Padre::Wx::Role::Main ();
use Padre::Wx             ();
use Padre::Wx::TreeCtrl   ();
use Padre::Logger;

our $VERSION = '0.86';
our @ISA     = qw{
	Padre::Role::Task
	Padre::Wx::Role::View
	Padre::Wx::Role::Main
	Padre::Wx::TreeCtrl
};





######################################################################
# Constructor

sub new {
	my $class = shift;
	my $main  = shift;
	my $panel = shift || $main->bottom;

	# Create the underlying object
	my $self = $class->SUPER::new(
		$panel,
		-1,
		Wx::wxDefaultPosition,
		Wx::wxDefaultSize,
		Wx::wxTR_SINGLE | Wx::wxTR_FULL_ROW_HIGHLIGHT | Wx::wxTR_HAS_BUTTONS | Wx::wxCLIP_CHILDREN
	);

	# Create the image list
	my $images = Wx::ImageList->new( 16, 16 );
	$self->{images} = {
		folder => $images->Add(
			Wx::ArtProvider::GetBitmap(
				'wxART_FOLDER',
				'wxART_OTHER_C',
				[ 16, 16 ],
			),
		),
		file => $images->Add(
			Wx::ArtProvider::GetBitmap(
				'wxART_NORMAL_FILE',
				'wxART_OTHER_C',
				[ 16, 16 ],
			),
		),
		result => $images->Add(
			Wx::ArtProvider::GetBitmap(
				'wxART_GO_FORWARD',
				'wxART_OTHER_C',
				[ 16, 16 ],
			),
		),
		root => $images->Add(
			Wx::ArtProvider::GetBitmap(
				'wxART_HELP_FOLDER',
				'wxART_OTHER_C',
				[ 16, 16 ],
			),
		),
	};
	$self->AssignImageList($images);

	# When a find result is clicked, open it
	Wx::Event::EVT_TREE_ITEM_ACTIVATED(
		$self, $self,
		sub {
			shift->_on_find_result_clicked(@_);
		}
	);

	# Inialise statistics
	$self->{files}   = 0;
	$self->{matches} = 0;

	return $self;
}





######################################################################
# Search Methods

sub search {
	my $self  = shift;
	my %param = @_;

	# If we are given a root and no project, and the root path
	# is precisely the root of a project, switch so that the search
	# will automatically pick up the manifest/skip rules for it.
	if ( defined $param{root} and not exists $param{project} ) {
		my $project = $self->ide->project_manager->project( $param{root} );
		$param{project} = $project if $project;
	}

	# Kick off the search task
	$self->task_reset;
	$self->clear;
	$self->task_request(
		task       => 'Padre::Task::FindInFiles',
		on_message => 'search_message',
		on_finish  => 'search_finish',
		%param,
	);

	my $root = $self->AddRoot('Root');
	$self->SetItemText(
		$root,
		sprintf( Wx::gettext(q{Searching for '%s' in '%s'...}), $param{search}->find_term, $param{root} )
	);
	$self->SetItemImage( $root, $self->{images}->{root} );

	return 1;
}

sub search_message {
	TRACE( $_[0] ) if DEBUG;
	my $self = shift;
	my $task = shift;
	my $path = shift;
	my $root = $self->GetRootItem;

	# Lock the tree to reduce flicker and prevent auto-scrolling
	my $lock = $self->scroll_lock;

	# Add the file node to the tree
	require Padre::Wx::Directory::Path; # added to avoid crash in next line
	my $name  = $path->name;
	my $dir   = File::Spec->catfile( $task->root, $path->dirs );
	my $full  = File::Spec->catfile( $task->root, $path->path );
	my $lines = scalar @_;
	my $label =
		$lines > 1
		? sprintf(
		Wx::gettext('%s (%s results)'),
		$full,
		$lines,
		)
		: $full;
	my $file = $self->AppendItem( $root, $label, $self->{images}->{file} );
	$self->SetPlData(
		$file,
		{   dir  => $dir,
			file => $name,
		}
	);

	# Add the lines nodes to the tree
	foreach my $row (@_) {

		# Tabs don't display properly
		$row->[1] =~ s/\t/    /g;
		my $line = $self->AppendItem(
			$file,
			$row->[0] . ': ' . $row->[1],
			$self->{images}->{result},
		);
		$self->SetPlData(
			$line,
			{   dir  => $dir,
				file => $name,
				line => $row->[0],
				msg  => $row->[1],
			}
		);
	}

	# Update statistics
	$self->{matches} += $lines;
	$self->{files}   += 1;

	# Ensure both the root and the new file are expanded
	$self->Expand($root);
	$self->Expand($file);

	return 1;
}

sub search_finish {
	TRACE( $_[0] ) if DEBUG;
	my $self = shift;
	my $task = shift;
	my $term = $task->{search}->find_term;
	my $dir  = $task->{root};

	# Display the summary
	my $root = $self->GetRootItem;
	if ( $self->{files} ) {
		$self->SetItemText(
			$root,
			sprintf(
				Wx::gettext(q{Search complete, found '%s' %d time(s) in %d file(s) inside '%s'}),
				$term,
				$self->{matches},
				$self->{files},
				$dir,
			)
		);
	} else {
		$self->SetItemText(
			$root,
			sprintf(
				Wx::gettext(q{No results found for '%s' inside '%s'}),
				$term,
				$dir,
			)
		);
	}

	return 1;
}

# Private method to handle the clicking of a find result
sub _on_find_result_clicked {
	my ( $self, $event ) = @_;

	my $item_data = $self->GetPlData( $event->GetItem ) or return;
	my $dir       = $item_data->{dir}                   or return;
	my $file      = $item_data->{file}                  or return;
	my $line      = $item_data->{line};
	my $msg = $item_data->{msg} || '';

	if ( defined $line ) {
		$self->open_file_at_line( File::Spec->catfile( $dir, $file ), $line - 1 );
	} else {
		$self->open_file_at_line( File::Spec->catfile( $dir, $file ) );
	}

	return;
}

# Opens the file at the correct line position
# If no line is given, the function just opens the file
# and sets the focus to it.
sub open_file_at_line {
	my ( $self, $file, $line ) = @_;

	return unless -f $file;
	my $main = $self->main;

	# Try to open the file now
	my $editor;
	if ( defined( my $page_id = $main->editor_of_file($file) ) ) {
		$editor = $main->notebook->GetPage($page_id);
	} else {
		$main->setup_editor($file);
		if ( defined( my $page_id = $main->editor_of_file($file) ) ) {
			$editor = $main->notebook->GetPage($page_id);
		}
	}

	# Center the current position on the found result's line if an editor is found.
	# NOTE: we are EVT_IDLE event to make sure we can do that after a file is opened.
	if ($editor) {
		Wx::Event::EVT_IDLE(
			$self,
			sub {
				if ( defined($line) ) {
					$editor->EnsureVisible($line);
					$editor->goto_pos_centerize( $editor->GetLineIndentPosition($line) );
				}
				$editor->SetFocus;
				Wx::Event::EVT_IDLE( $self, undef );
			},
		);
	}

	return;
}

######################################################################
# Padre::Wx::Role::View Methods

sub view_panel {
	return 'bottom';
}

sub view_label {
	shift->gettext_label(@_);
}

sub view_close {
	$_[0]->task_reset;
	$_[0]->main->show_findinfiles(0);
}





#####################################################################
# General Methods

sub bottom {
	warn "Unexpectedly called Padre::Wx::Output::bottom, it should be deprecated";
	shift->main->bottom;
}

sub gettext_label {
	Wx::gettext('Find in Files');
}

sub select {
	my $self   = shift;
	my $parent = $self->GetParent;
	$parent->SetSelection( $parent->GetPageIndex($self) );
	return;
}

sub clear {
	my $self = shift;
	$self->{files}   = 0;
	$self->{matches} = 0;

	$self->DeleteAllItems;
	return 1;
}

1;

# Copyright 2008-2011 The Padre development team as listed in Padre.pm.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.
