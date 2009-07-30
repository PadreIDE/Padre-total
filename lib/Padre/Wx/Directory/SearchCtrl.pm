package Padre::Wx::Directory::SearchCtrl;

use strict;
use warnings;
use Padre::Current ();
use Padre::Wx      ();
use Padre::Wx::Directory::SearchTask;

our $VERSION = '0.41';
our @ISA     = 'Wx::SearchCtrl';

# Create a new Search object and show a search text field above the tree
sub new {
	my $class = shift;
	my $panel = shift;
	my $self  = $class->SUPER::new(
		$panel, -1, '',
		Wx::wxDefaultPosition,
		Wx::wxDefaultSize,
		Wx::wxTE_PROCESS_ENTER
	);

	# Caches each project search WORD and result
	$self->{CACHED} = {};

	# Text that is showed when the search field is empty
	$self->SetDescriptiveText( Wx::gettext('Search') );

	# Setups the search box menu
	$self->SetMenu($self->create_menu);

	# Setups events related with the search field
	Wx::Event::EVT_TEXT(
		$self, $self,
		\&_on_text
	);

	Wx::Event::EVT_SEARCHCTRL_CANCEL_BTN(
		$self, $self,
		sub {
			$self->SetValue('');
		}
	);

	Wx::Event::EVT_SET_FOCUS(
		$self,
		sub {
			$_[0]->parent->refresh;
		},
	);

	$self->{task} = Padre::Wx::Directory::SearchTask->new(
				directoryx => $self->parent,
				cache => $self->{CACHED},
			);

	return $self;
}

# Returns the Directory Panel object reference
sub parent {
	$_[0]->GetParent;
}

# Returns the main object reference
sub main {
	$_[0]->GetParent->main;
}

# Traverse to the sibling tree widget
sub tree {
	$_[0]->GetParent->tree;
}

sub current {
	Padre::Current->new( main => $_[0]->main );
}

# Called by Directory.pm
sub refresh {
	my $self   = shift;
	my $parent = $self->parent;

	# Gets the last and current actived projects
	my $project_dir  = $parent->project_dir;
	my $previous_dir = $parent->previous_dir;

	# Compares if they are not the same, if not updates search field
	# content
	if (
		defined($project_dir)
		and
		defined($previous_dir)
		and
		$previous_dir ne $project_dir
	) {
		$self->{use_cache} = 1;
		my $value = $self->{CACHED}->{$project_dir}->{value};
		$self->SetValue( defined $value ? $value : '' );

		# Checks the currently mode view
		my $mode = "sub_" . $parent->mode;
		$self->{$mode}->Check( 1 );

		# (Un)Checks current project Searcher Menu Skips options
		my $skips_hidden = $self->{_skip_hidden}->{ $project_dir };
		my $skips_vcs = $self->{_skip_vcs}->{ $project_dir };

		$self->{skip_hidden}->Check( defined $skips_hidden ? $skips_hidden : 1 );
		$self->{skip_vcs}->Check( defined $skips_vcs ? $skips_vcs : 1 );
	}
}

# Create the dropdown menu attached to the looking glass icon
sub create_menu {
	my $self        = shift;
	my $parent      = $self->parent;
	my $project_dir = $parent->project_dir;
	my $menu        = Wx::Menu->new;

	# Skip hidden files
	$self->{skip_hidden} = $menu->AppendCheckItem( -1,
		Wx::gettext('Skip hidden files')
	);
	$self->{skip_hidden}->Check(1);

	Wx::Event::EVT_MENU(
		$self,
		$self->{skip_hidden},
		sub {
			$self->{_skip_hidden}->{$project_dir}
				= $self->{skip_hidden}->IsChecked ? 1 : 0;
		},
	);

	# Skip CVS / .svn / blib and .git folders
	$self->{skip_vcs} = $menu->AppendCheckItem( -1,
		Wx::gettext('Skip CVS/.svn/.git/blib folders')
	);
	$self->{skip_vcs}->Check(1);

	Wx::Event::EVT_MENU(
		$self,
		$self->{skip_vcs},
		sub {
			$self->{_skip_vcs}->{$project_dir}
				= $self->{skip_vcs}->IsChecked ? 1 : 0;
		},
	);
	$menu->AppendSeparator();

	# Changes the project directory
	$self->{project_dir} = $menu->Append( -1,
		Wx::gettext('Change project directory')
	);

	Wx::Event::EVT_MENU(
		$self,
		$self->{project_dir},
		sub {
			$_[0]->parent->_change_project_dir;
		}
	);

	# Changes the Tree mode view
	my $submenu           = Wx::Menu->new;
	$self->{sub_tree}     = $submenu->AppendRadioItem( 1, Wx::gettext('Tree listing') );
	$self->{sub_navigate} = $submenu->AppendRadioItem( 2, Wx::gettext('Navigate') );
	$self->{mode}         = $menu->AppendSubMenu( $submenu, Wx::gettext('Change listing mode view') );
	$self->{sub_navigate}->Check(1);

	Wx::Event::EVT_MENU(
		$submenu,
		$self->{sub_tree},
		sub {
			$parent->{projects}->{$parent->project_dir}->{mode} = 'tree';
			$parent->{mode_change} = 1;
			$parent->refresh;
		}
	);

	Wx::Event::EVT_MENU(
		$submenu,
		$self->{sub_navigate},
		sub {
			$parent->{projects}->{$parent->project_dir}->{mode} = 'navigate';
			$parent->{mode_change} = 1;
			$parent->refresh;
		}
	);

	# Changes the panel side
	$self->{move_panel} = $menu->Append( -1,
		Wx::gettext('Move to other panel')
	);

	Wx::Event::EVT_MENU(
		$self,
		$self->{move_panel},
		sub {
			$_[0]->parent->move;
		}
	);

	return $menu;
}

# If it is a project, caches search field content while it is typed and
# searchs for files that matchs the type word
sub _on_text {
	my $self        = shift;
	my $parent      = $self->parent;
	my $tree        = $self->tree;
	my $value       = $self->GetValue;
	my $project_dir = $parent->project_dir or return;

	# If nothing is typed hides the Cancel button
	# and sets that the search is not in use
	unless ( $value ) {
		# Hides Cancel Button
		$self->ShowCancelButton(0);

		# Sets that the search for this project was just used
		# and is not in use anymore
		$self->{just_used}->{ $project_dir } = 1;
		delete $self->{in_use}->{ $project_dir };
		delete $self->{CACHED}->{ $project_dir };

		# Updates the Directory Browser window
		$self->tree->refresh;

		return;
	}

	# Sets that the search is in use
	$self->{in_use}->{ $project_dir } = 1;

	# Lock the gui here to make the updates look slicker
	# The locker holds the gui freeze until the update is done.
	my $locker = $self->main->freezer;

	# Schedules the search in background
	$self->{task}->schedule;

	return 1;
}

1;

# Copyright 2008-2009 The Padre development team as listed in Padre.pm.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.
