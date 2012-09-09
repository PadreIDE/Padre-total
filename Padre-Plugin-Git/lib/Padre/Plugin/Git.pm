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
use File::Which       ();
use Try::Tiny;

our $VERSION = '0.04';
use parent qw(Padre::Plugin);

#########
# We need plugin_enable
# as we have an external dependency git
#########
sub plugin_enable {
	my $self             = shift;
	my $local_git_exists = 0;

	try {
		if ( File::Which::which('git') ) {
			$local_git_exists = 1;
		}
	};

	return $local_git_exists;
}

# Child modules we need to unload when disabled
use constant CHILDREN => qw{
	Padre::Plugin::Git
	Padre::Wx::Dialog::Text
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
			Wx::gettext('Add file') => sub {
				$self->git_stage_file;
			},
			Wx::gettext('Add all') => sub {
				$self->git_stage_all;
			},
			Wx::gettext('reset HEAD file') => sub {
				$self->git_unstage_file;
			},
		],
		Wx::gettext('Commit') => [
			Wx::gettext('Commit File') => sub {
				$self->git_commit_file;
			},
			Wx::gettext('Commit Project') => sub {
				$self->git_commit_project;
			},
			Wx::gettext('git commit -a') => sub {
				$self->git_commit_a;
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
			Wx::gettext('Diff of staged File') => sub {
				$self->git_diff_of_file_staged;
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

	$self->current_files;
	my $tab_id = $self->main->editor_of_file( $document->{filename} );
	if ( $self->{open_file_info}->{$tab_id}->{'vcs'} =~ m/Git/sxm ) {

		my $message;
		my $git_cmd;
		if ( $action =~ m/^commit/ ) {
			$message = $main->prompt( "Git Commit of $location", "Please type in your message", "MY_GIT_COMMIT" );

			return if not $message;

			require Padre::Util;
			$git_cmd = Padre::Util::run_in_directory_two(
				cmd    => "git $action $location -m \"$message\"",
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

		if ( $action !~ m/^diff/ ) {

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

			#ToDo Padre::Wx::Dialog::Text needs to be updated with FormBuilder
			require Padre::Wx::Dialog::Text;
			Padre::Wx::Dialog::Text->show( $main, "Git $action -> $location", $git_cmd->{output} );
		} else {
			return 0;
		}
	}

	return;
}


#######
# stage_file
#######
sub git_stage_file {
	my $self     = shift;
	my $main     = $self->main;
	my $document = $main->current->document;
	$self->git_cmd( 'add',    $document->filename );
	$self->git_cmd( 'status', $document->filename );
	return;
}
#######
# stage_file
#######
sub git_stage_all {
	my $self     = shift;
	my $main     = $self->main;
	my $document = $main->current->document;
	$self->git_cmd( 'add',    $document->project_dir );
	$self->git_cmd( 'status', $document->project_dir );
	return;
}
#######
# unstage_file
#######
sub git_unstage_file {
	my $self     = shift;
	my $main     = $self->main;
	my $document = $main->current->document;

	#ToDO mj41 should we be using this instead
	#$self->git_cmd( 'rm --cached', $document->filename );
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
# git_commit_project
#######
sub git_commit_a {
	my $self     = shift;
	my $main     = $self->main;
	my $document = $main->current->document;
	$self->git_cmd( 'commit -a', '' );
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
	my $result   = $self->git_cmd( 'diff', $document->filename );
	if ( !$result ) {
		$self->git_cmd( 'diff --cached', $document->filename );
	}
	return;
}
#######
# git_diff_of_file_staged
#######
sub git_diff_of_file_staged {
	my $self     = shift;
	my $main     = $self->main;
	my $document = $main->current->document;
	$self->git_cmd( 'diff --cached', $document->filename );
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
#######
# event_on_context_menu
#######
sub event_on_context_menu {
	my ( $self, $document, $editor, $menu, $event ) = @_;

	$self->current_files;
	return if not $document->filename;
	return if not $document->project_dir;

	my $tab_id = $self->main->editor_of_file( $document->{filename} );

	# p $self->{open_file_info}->{$tab_id}->{'vcs'};
	if ( $self->{open_file_info}->{$tab_id}->{'vcs'} =~ m/Git/sxm ) {

		$menu->AppendSeparator;

		my $item = $menu->Append( -1, Wx::gettext('Git commit -a') );
		Wx::Event::EVT_MENU(
			$self->main,
			$item,
			sub { $self->git_commit_a },
		);




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

=head1 VERSION

version 0.04

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
