package Padre::Plugin::Git;

use v5.10;
use warnings;
use strict;

use Padre::Unload;
use Padre::Config     ();
use Padre::Wx         ();
use Padre::Plugin     ();
use Padre::Util       ();
use Padre::Wx::Action ();
use File::Basename    ();

our $VERSION = '0.04';
use parent qw(Padre::Plugin);

# Child modules we need to unload when disabled
use constant CHILDREN => qw{
	Padre::Plugin::Git
};

#######
# Called by padre to check the required interface
#######
sub padre_interfaces {
	return (
		# Default, required
		'Padre::Plugin' => '0.96',

		'Padre::Unload'     => '0.96',
		'Padre::Config'     => '0.96',
		'Padre::Wx'         => '0.96',
		'Padre::Wx::Action' => '0.96',
		'Padre::Util'       => '0.97',
	);
}

#######
# Called by padre to know the plugin name
#######
sub plugin_name {
	return Wx::gettext('Git');
}

#######
# Add Plugin to Padre Menu
#######
sub menu_plugins_simple {
	my $self = shift;
	return $self->plugin_name => [
		Wx::gettext('About...') => sub {
			$self->show_about;
		},
		Wx::gettext('Staging') => [
			Wx::gettext('Add') => sub {
				$self->stage_file;
			},
			Wx::gettext('reset HEAD') => sub {
				$self->unstage_file;
			},
		],
		Wx::gettext('Commit') => [
			Wx::gettext('Commit File') => sub {
				$self->git_commit_file;
			},
			Wx::gettext('Commit Project') => sub {
				$self->git_commit_project;
			},
		],
		Wx::gettext('Status') => [
			Wx::gettext('File Status') => sub {
				$self->git_status_of_file;
			},
			Wx::gettext('Directory Status') => sub {
				$self->git_status_of_dir;
			},
			Wx::gettext('Project Status') => sub {
				$self->git_status_of_project;
			},
		],
		Wx::gettext('Diff') => [
			Wx::gettext('Diff of File') => sub {
				$self->git_diff_of_file;
			},
			Wx::gettext('Diff of Dir') => sub {
				$self->git_diff_of_dir;
			},
			Wx::gettext('Diff of Project') => sub {
				$self->git_diff_of_project;
			},
		],

	];
}

#######
# show_about
#######
sub show_about {
	my $self = shift;

	# Generate the About dialog
	my $about = Wx::AboutDialogInfo->new;
	$about->SetName("Padre::Plugin::Git");
	$about->SetDescription( <<"END_MESSAGE" );
Initial Git support for Padre
END_MESSAGE
	$about->SetVersion($VERSION);

	# Show the About dialog
	Wx::AboutBox($about);

	return;
}

#######
# git_commit
#######
sub git_cmd {
	my $self     = shift;
	my $action   = shift;
	my $location = shift;
	my $main     = $self->main;
	my $document = $main->current->document;

	my $message;
	my $git_cmd;
	if ( $action eq 'commit' ) {
		$message = $main->prompt( "Git Commit of $location", "Please type in your message", "MY_GIT_COMMIT" );

		return if not $message;

		require Padre::Util;
		$git_cmd = Padre::Util::run_in_directory_two(
			cmd    => "git commit $location -m \"$message\"",
			dir    => $document->project_dir,
			option => 0
		);
	} else {
		require Padre::Util;
		$git_cmd = Padre::Util::run_in_directory_two(
			cmd    => "git $action $location",
			dir    => $document->project_dir,
			option => 0
		);
	}

	if ( $action ne 'diff' ) {

		#strip leading #
		$git_cmd->{output} =~ s/^(\#)//sxmg;
	}

	#Display correct result
	if ( $git_cmd->{error} ) {
		$main->error(
			sprintf(
				Wx::gettext("Git Error follows -> \n\n%s"),
				$git_cmd->{error}
			),
		);
	} elsif ( $git_cmd->{output} ) {
		require Padre::Wx::Dialog::Text;
		Padre::Wx::Dialog::Text->show( $main, "Git $action -> $location", $git_cmd->{output} );
	}

	return;
}


#######
# stage_file
#######
sub stage_file {
	my $self     = shift;
	my $main     = $self->main;
	my $document = $main->current->document;
	$self->git_cmd( 'add',    $document->filename );
	$self->git_cmd( 'status', $document->filename );
	return;
}

#######
# unstage_file
#######
sub unstage_file {
	my $self     = shift;
	my $main     = $self->main;
	my $document = $main->current->document;
	$self->git_cmd( 'reset HEAD', $document->filename );
	$self->git_cmd( 'status',     $document->filename );
	return;
}


#######
# git_commit_file
#######
sub git_commit_file {
	my $self     = shift;
	my $main     = $self->main;
	my $document = $main->current->document;
	$self->git_cmd( 'commit', $document->filename );
	return;
}

#######
# git_commit_project
#######
sub git_commit_project {
	my $self     = shift;
	my $main     = $self->main;
	my $document = $main->current->document;
	$self->git_cmd( 'commit', $document->project_dir );
	return;
}

#######
# git_status_of_file
#######
sub git_status_of_file {
	my $self     = shift;
	my $main     = $self->main;
	my $document = $main->current->document;
	$self->git_cmd( 'status', $document->filename );
	return;
}

#######
# git_status_of_dir
#######
sub git_status_of_dir {
	my $self     = shift;
	my $main     = $self->main;
	my $document = $main->current->document;
	$self->git_cmd( 'status', File::Basename::dirname( $document->filename ) );
	return;
}

#######
# git_status_of_project
#######
sub git_status_of_project {
	my $self     = shift;
	my $main     = $self->main;
	my $document = $main->current->document;
	$self->git_cmd( 'status', $document->project_dir );
	return;
}


#######
# git_diff_of_file
#######
sub git_diff_of_file {
	my $self     = shift;
	my $main     = $self->main;
	my $document = $main->current->document;
	$self->git_cmd( 'diff', $document->filename );
	return;
}

#######
# git_diff_of_dir
#######
sub git_diff_of_dir {
	my $self     = shift;
	my $main     = $self->main;
	my $document = $main->current->document;
	$self->git_cmd( 'diff', File::Basename::dirname( $document->filename ) );
	return;
}

#######
# git_diff_of_project
#######
sub git_diff_of_project {
	my $self     = shift;
	my $main     = $self->main;
	my $document = $main->current->document;
	$self->git_cmd( 'diff', $document->project_dir );
	return;
}


#ToDo this sub breaks Padre 0.96, Padre 0.97+ good to go :), needs to be padre-plugin api v2.2 compatable
# This thing should just list a few actions
sub event_on_context_menu {
	my ( $self, $document, $editor, $menu, $event ) = @_;

	$self->current_files;
	return if not $document->filename;
	return if not $document->project_dir;

	my $tab_id = $self->main->editor_of_file( $document->{filename} );

	# p $self->{open_file_info}->{$tab_id}->{'vcs'};
	if ( $self->{open_file_info}->{$tab_id}->{'vcs'} =~ m/Git/sxm ) {

		$menu->AppendSeparator;

		# my $menu_rcs = Wx::Menu->new;
		my $menu_rcs = $self->menu_plugins_simple;

		#ToDo ask Adam how do we ad a sub menu here?
		$menu->Append( -1, Wx::gettext('Git'), $menu_rcs );
	}

	return;
}

#######
# Method current_files hacked from wx-dialog-patch
#######
sub current_files {
	my $self     = shift;
	my $main     = $self->main;
	my $current  = $main->current;
	my $notebook = $current->notebook;
	my @label    = $notebook->labels;

	# get last element # not size
	$self->{tab_cardinality} = $#label;

	# thanks Alias
	my @file_vcs = map { $_->project->vcs } $self->main->documents;

	# create a bucket for open file info, as only a current file bucket exist
	for ( 0 .. $self->{tab_cardinality} ) {
		$self->{open_file_info}->{$_} = (
			{   'index'    => $_,
				'URL'      => $label[$_][1],
				'filename' => $notebook->GetPageText($_),
				'changed'  => 0,
				'vcs'      => $file_vcs[$_],
			},
		);

		if ( $notebook->GetPageText($_) =~ /^\*/sxm ) {

			# TRACE("Found an unsaved file, will ignore: $notebook->GetPageText($_)") if DEBUG;
			$self->{open_file_info}->{$_}->{'changed'} = 1;
		}
	}

	return;
}

########
# plugin_disable
########
sub plugin_disable {
	my $self = shift;

	# Close the dialog if it is hanging around
	$self->clean_dialog;

	# Unload all our child classes
	for my $package (CHILDREN) {
		require Padre::Unload;
		Padre::Unload->unload($package);
	}

	$self->SUPER::plugin_disable(@_);

	return 1;
}

########
# Composed Method clean_dialog
########
sub clean_dialog {
	my $self = shift;

	# Close the main dialog if it is hanging around
	if ( $self->{dialog} ) {
		$self->{dialog}->Hide;
		$self->{dialog}->Destroy;
		delete $self->{dialog};
	}

	return 1;
}

1;

__END__

=head1 NAME

Padre::Plugin::Git - Simple Git interface for Padre, the Perl IDE,

=head1 SYNOPSIS

cpan install Padre::Plugin::Git

Access it via Plugin/Git


=head1 AUTHOR

Kevin Dawson E<lt>bowtie@cpan.orgE<gt>

Kaare Rasmussen, C<< <kaare at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to L<http://padre.perlide.org/>


=head1 COPYRIGHT & LICENSE

Copyright 2008-2012 The Padre development team as listed in Padre.pm in the
Padre distribution all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

# Copyright 2008-2012 The Padre development team as listed in Padre.pm.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.


###########
cruff store for convience only


# should be called once when loading the plugin
my $ONCE;

sub define_actions {
	my $self = shift;
	return if $ONCE;
	$ONCE = 1;
	Padre::Wx::Action->new(
		name        => 'git.about',
		label       => Wx::gettext('About'),
		comment     => Wx::gettext('Show information about the Git plugin'),
		need_editor => 0,
		menu_event  => sub {
			$self->show_about;
		},
	);

	Padre::Wx::Action->new(
		name        => 'git.commit_file',
		label       => Wx::gettext('Commit File'),
		comment     => Wx::gettext('Commit File'),
		need_editor => 0,
		menu_event  => sub {
			$self->git_commit_file;
		},
	);

	Padre::Wx::Action->new(
		name        => 'git.commit_project',
		label       => Wx::gettext('Commit Project'),
		comment     => Wx::gettext('Commit Project'),
		need_editor => 0,
		menu_event  => sub {
			$self->git_commit_project;
		},
	);

	Padre::Wx::Action->new(
		name        => 'git.status_of_file',
		label       => Wx::gettext('File Status'),
		comment     => Wx::gettext('Show the status of the current file'),
		need_editor => 0,
		menu_event  => sub {
			$self->git_status_of_file;
		},
	);

	Padre::Wx::Action->new(
		name        => 'git.status_of_dir',
		label       => Wx::gettext('Directory Status'),
		comment     => Wx::gettext('Show the status of the current directory'),
		need_editor => 0,
		menu_event  => sub {
			$self->git_status_of_dir;
		},
	);

	Padre::Wx::Action->new(
		name        => 'git.status_of_project',
		label       => Wx::gettext('Project Status'),
		comment     => Wx::gettext('Show the status of the current project'),
		need_editor => 0,
		menu_event  => sub {
			$self->git_status_of_project;
		},
	);

	Padre::Wx::Action->new(
		name        => 'git.diff_of_file',
		label       => Wx::gettext('Diff of File'),
		comment     => Wx::gettext('Diff of File'),
		need_editor => 0,
		menu_event  => sub {
			$self->git_diff_of_file;
		},
	);

	Padre::Wx::Action->new(
		name        => 'git.diff_of_dir',
		label       => Wx::gettext('Diff of Dir'),
		comment     => Wx::gettext('Diff of Dir'),
		need_editor => 0,
		menu_event  => sub {
			$self->git_diff_of_dir;
		},
	);

	Padre::Wx::Action->new(
		name        => 'git.diff_of_project',
		label       => Wx::gettext('Diff of Project'),
		comment     => Wx::gettext('Diff of Project'),
		need_editor => 0,
		menu_event  => sub {
			$self->git_diff_of_project;
		},
	);


	return;
}

sub menu_actions {
	my $self = shift;
	$self->define_actions();

	return $self->plugin_name => [
		'git.about',
		[   'Commit...',
			'git.commit_file',
			'git.commit_project',
		],
		[   'Status...',
			'git.status_of_file',
			'git.status_of_dir',
			'git.status_of_project',
		],

		[   'Diff...',
			'git.diff_of_file',
			'git.diff_of_dir',
			'git.diff_of_project',
		],
	];
}

sub rightclick_actions {
	my $self = shift;
	return $self->menu_actions;
}

