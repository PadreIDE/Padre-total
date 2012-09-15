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
use parent qw(
	Padre::Plugin
	Padre::Role::Task
);

use Data::Printer {
	caller_info => 1,
	colored     => 1,
};


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
	Padre::Plugin::Git::Task::Git_cmd
	Padre::Plugin::Git::Task::GitHub
	Padre::Plugin::Git::Output
	Padre::Plugin::Git::FBP::Output
	Pithub
	Pithub::PullRequests
};

#######
# Called by padre to check the required interface
#######
sub padre_interfaces {
	return (
		# Default, required
		'Padre::Plugin'     => '0.96',
		'Padre::Task'       => '0.96',
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
	my $self     = shift;
	my $main     = $self->main;
	my $document = $main->current->document;

	#Hide Git on Tools menu if current file is not in a Git controled dir
	$self->current_files;
	my $tab_id = $self->main->editor_of_file( $document->{filename} );
	try {
		if ( defined $tab_id ) {
			if ( $self->{open_file_info}->{$tab_id}->{'vcs'} =~ m/Git/sxm ) {

				return $self->plugin_name => [
					Wx::gettext('About...') => sub {
						$self->show_about;
					},
					Wx::gettext('Local') => [
						Wx::gettext('Staging') => [
							Wx::gettext('Stage File') => sub {
								$self->git_cmd( 'add',    $document->filename );
								$self->git_cmd( 'status', $document->filename );
							},
							Wx::gettext('Stage All') => sub {
								$self->git_cmd( 'add',    $document->project_dir );
								$self->git_cmd( 'status', $document->project_dir );
							},
							Wx::gettext('Unstage File') => sub {

								#ToDo mj41 should we be using this instead
								#$self->git_cmd( 'rm --cached', $document->filename );
								$self->git_cmd( 'reset HEAD', $document->filename );
								$self->git_cmd( 'status',     $document->filename );
							},
						],
						Wx::gettext('Commit') => [
							Wx::gettext('Commit File') => sub {
								$self->git_cmd( 'commit', $document->filename );
							},
							Wx::gettext('Commit Project') => sub {
								$self->git_cmd( 'commit', $document->project_dir );
							},
							Wx::gettext('Commit Amend') => sub {
								$self->git_cmd( 'commit --amend', '' );
							},
							Wx::gettext('Commit All') => sub {
								$self->git_cmd( 'commit -a', '' );
							},
						],
						Wx::gettext('Checkout') => [
							Wx::gettext('Checkout File') => sub {
								$self->git_cmd( 'checkout --', $document->filename );
							},
						],
						Wx::gettext('Status') => [
							Wx::gettext('File Status') => sub {
								$self->git_cmd( 'status', $document->filename );
							},
							Wx::gettext('Directory Status') => sub {
								self->git_cmd( 'status', File::Basename::dirname( $document->filename ) );
							},
							Wx::gettext('Project Status') => sub {
								$self->git_cmd( 'status', $document->project_dir );
							},
						],
						Wx::gettext('Diff') => [
							Wx::gettext('Diff of File') => sub {
								my $result = $self->git_cmd( 'diff', $document->filename );
							},
							Wx::gettext('Diff of Staged File') => sub {
								$self->git_cmd( 'diff --cached', $document->filename );
							},
							Wx::gettext('Diff of Directory') => sub {
								$self->git_cmd( 'diff', File::Basename::dirname( $document->filename ) );
							},
							Wx::gettext('Diff of Project') => sub {
								$self->git_cmd( 'diff', $document->project_dir );
							},
						],
						Wx::gettext('Log') => [
							Wx::gettext('log --stat -2') => sub {
								$self->git_cmd( 'log --stat -2', '' );
							},
							Wx::gettext('log -p -2') => sub {
								$self->git_cmd( 'log -p -2', '' );
							},
							Wx::gettext('log pretty') => sub {
								$self->git_cmd( 'log --pretty=format:"%h %s" --graph', '' );
							},
						],
					],
					Wx::gettext('Origin') => [
						Wx::gettext('Show Origin Info.') => sub {
							$self->git_cmd_task( 'remote show origin', '' );
						},
						Wx::gettext('Push to Origin') => sub {
							$self->git_cmd_task( 'push origin master', '' );
						},
						Wx::gettext('Fetch from Origin') => sub {
							$self->git_cmd_task( 'fetch origin master', '' );
						},
						Wx::gettext('Pull from Origin') => sub {
							$self->git_cmd_task( 'pull origin master', '' );
						},
					],
					Wx::gettext('Upstream') => [
						Wx::gettext('Show Upstream Info.') => sub {
							$self->git_cmd_task( 'remote show upstream', '' );
						},
						Wx::gettext('Fetch Upstream') => sub {
							$self->git_cmd_task( 'fetch upstream', '' );
						},
						Wx::gettext('Merge Upstream Master') => sub {
							$self->git_cmd_task( 'merge upstream/master', '' );
						},
					],
					Wx::gettext('GitHub') => [
						Wx::gettext('GitHub Pull Request') => sub {

							# $self->github_task();
							$self->github_pull_request();
						},
					],
				];
			}
		}
	};
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

	# $self->current_files;
	# my $tab_id = $self->main->editor_of_file( $document->{filename} );
	# if ( $self->{open_file_info}->{$tab_id}->{'vcs'} =~ m/Git/sxm ) {

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

	#ToDo sort out Fudge, why O why do we not get correct response
	# p $git_cmd;
	if ( $action =~ m/^push/ ) {
		$git_cmd->{output} = $git_cmd->{error};
		$git_cmd->{error}  = undef;
	}

	# p $git_cmd;

	#Display correct result
	try {
		if ( $git_cmd->{error} ) {
			$main->error(
				sprintf(
					Wx::gettext("Git Error follows -> \n\n%s"),
					$git_cmd->{error}
				),
			);
		}
		if ( $git_cmd->{output} ) {

			#ToDo Padre::Wx::Dialog::Text needs to be updated with FormBuilder
			# require Padre::Wx::Dialog::Text;
			# Padre::Wx::Dialog::Text->show( $main, "Git $action -> $location", $git_cmd->{output} );
			$self->load_dialog_output( "Git $action -> $location", $git_cmd->{output} );
		} else {
			$main->info( Wx::gettext('Info: There is no response, just as if you had run it on the cmd yourself.') );
		}
	};

	# }

	return;
}

#######
# github_pull_request
#######
sub github_pull_request {
	my $self     = shift;
	my $main     = $self->main;
	my $document = $main->current->document;

	# Lets start with username and token being external to pp-git
	my $user  = $ENV{GITHUB_USER};
	my $token = $ENV{GITHUB_TOKEN};

	unless ( $user && $token ) {
		$main->error(
			Wx::gettext(
				      'Error: missing $ENV{GITHUB_USER} and $ENV{GITHUB_TOKEN}' . "\n"
					. 'See http://padre.perlide.org/trac/wiki/PadrePluginGit' . "\n"
					. 'Wiki page for more info.'
			)
		);
		return;
	}

	my $message = $main->prompt( "GitHub Pull Request", "Please type in your message" );
	return if not $message;

	#Use first 32 chars of message as pull request title
	my $title = substr $message, 0, 32;


	my $git_cmd;
	require Padre::Util;
	$git_cmd = Padre::Util::run_in_directory_two(
		cmd    => "git remote show upstream",
		dir    => $document->project_dir,
		option => 0
	);

	try {

		if ( defined $git_cmd->{error} ) {
			if ( $git_cmd->{error} =~ m/^fatal/ ) {

				# $self->{error} = 'dose not have an upstream componet';
				say 'dose not have an upstream componet';
				$main->error( Wx::gettext('Error: this repo dose not have an upstream componet') );
				return;
			}
		}
	};

	my $test_output = $git_cmd->{output};
	$test_output =~ m{(?<=https://github.com/)(?<author>.*)(?:/)(?<repo>.*)(?:.git)};
	my $author = $+{author};
	my $repo   = $+{repo};

	require Pithub;
	my $github = Pithub->new(
		repo  => $repo,
		token => $token,
		user  => $user,
	);

	my $status = $github->pull_requests->create(
		repo => $repo,
		user => $author,
		data => {
			base  => "$author:master",
			body  => $message,
			head  => "$user:master",
			title => $title,
		}
	);

	if ( $status->success eq 1 ) {
		$main->message(
			sprintf(
				Wx::gettext("Info: Cool we got a: %s \nNow you should check your GitHub repo\n https://github.com/%s"),
				$status->response->{_rc},
				$user,
			)
		);
	} else {
		$main->error(
			sprintf(
				Wx::gettext("Error: %s\n%s"),
				$status->response->{_rc},
				$status->response->{_content},
			)
		);
	}

	return;
}


#######
# github_task
#######
sub github_task {
	my $self = shift;

	# my $action   = shift;
	# my $location = shift;
	my $main     = $self->main;
	my $document = $main->current->document;

	my $message = $main->prompt( "GitHub Pull Request", "Please type in your message" );
	return if not $message;

	require Padre::Plugin::Git::Task::GitHub;

	# Fire the task
	$self->task_request(
		task        => 'Padre::Plugin::Git::Task::GitHub',
		message     => $message,
		action      => 'remote show upstream',
		location    => '',
		project_dir => $document->project_dir,
		on_finish   => 'on_finish',
	);

	# }

	return;
}
#######
# git_cmd_task
#######
sub git_cmd_task {
	my $self     = shift;
	my $action   = shift;
	my $location = shift;
	my $main     = $self->main;
	my $document = $main->current->document;

	# $self->current_files;
	# my $tab_id = $self->main->editor_of_file( $document->{filename} );
	# if ( $self->{open_file_info}->{$tab_id}->{'vcs'} =~ m/Git/sxm ) {

	require Padre::Plugin::Git::Task::Git_cmd;

	# Fire the task
	$self->task_request(
		task        => 'Padre::Plugin::Git::Task::Git_cmd',
		action      => $action,
		location    => $location,
		project_dir => $document->project_dir,
		on_finish   => 'on_finish',
	);

	# }

	return;
}
#######
# on compleation of task do this
#######
sub on_finish {
	my $self = shift;
	my $task = shift;
	my $main = $self->main;

	p $task->{error};
	p $task->{output};

	if ( $task->{error} ) {
		$main->error(
			sprintf(
				Wx::gettext("Git Error follows -> \n\n%s"),
				$task->{error}
			),
		);
	} elsif ( $task->{output} ) {

		#ToDo Padre::Wx::Dialog::Text needs to be updated with FormBuilder
		# require Padre::Wx::Dialog::Text;
		# Padre::Wx::Dialog::Text->show( $main, "Git $task->{action} -> $task->{location}", $task->{output} );
		$self->load_dialog_output( "Git task->{action} -> $task->{location}", $task->{output} );

	} else {
		$main->info( Wx::gettext('Info: There is no response, just as if you had run it on the cmd yourself.') );
	}
	return;
}

########
# Composed Method,
# Load Output dialog, only once
#######
sub load_dialog_output {
	my $self  = shift;
	my $title = shift;
	my $text  = shift;

	# Padre main window integration
	my $main = $self->main;

	# Close the dialog if it is hanging around
	$self->clean_dialog;

	# Create the new dialog
	require Padre::Plugin::Git::Output;
	$self->{dialog} = Padre::Plugin::Git::Output->new( $main, $title, $text );
	$self->{dialog}->Show;

	return;
}

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
			sub { $self->git_cmd( 'commit -a', '' ) },
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





#####################

#######
# stage_file
#######
# sub git_stage_file {
# my $self     = shift;
# my $main     = $self->main;
# my $document = $main->current->document;
# $self->git_cmd( 'add',    $document->filename );
# $self->git_cmd( 'status', $document->filename );
# return;
# }
#######
# stage_file
#######
# sub git_stage_all {
# my $self     = shift;
# my $main     = $self->main;
# my $document = $main->current->document;
# $self->git_cmd( 'add',    $document->project_dir );
# $self->git_cmd( 'status', $document->project_dir );
# return;
# }
#######
# unstage_file
#######
# sub git_unstage_file {
# my $self     = shift;
# my $main     = $self->main;
# my $document = $main->current->document;

# #ToDO mj41 should we be using this instead
# #$self->git_cmd( 'rm --cached', $document->filename );
# $self->git_cmd( 'reset HEAD', $document->filename );
# $self->git_cmd( 'status',     $document->filename );
# return;
# }


#######
# git_commit_file
#######
# sub git_commit_file {
# my $self     = shift;
# my $main     = $self->main;
# my $document = $main->current->document;
# $self->git_cmd( 'commit', $document->filename );
# return;
# }
#######
# git_commit_project
#######
# sub git_commit_project {
# my $self     = shift;
# my $main     = $self->main;
# my $document = $main->current->document;
# $self->git_cmd( 'commit', $document->project_dir );
# return;
# }
#######
# git_commit_amend
#######
# sub git_commit_amend {
# my $self     = shift;
# my $main     = $self->main;
# my $document = $main->current->document;
# $self->git_cmd( 'commit --amend', '' );
# return;
# }
#######
# git_commit_project
#######
# sub git_commit_a {
# my $self     = shift;
# my $main     = $self->main;
# my $document = $main->current->document;
# $self->git_cmd( 'commit -a', '' );
# return;
# }


#######
# git_checkout_file
#######
# sub git_checkout_file {
# my $self     = shift;
# my $main     = $self->main;
# my $document = $main->current->document;
# $self->git_cmd( 'checkout --', $document->filename );
# return;
# }


#######
# git_status_of_file
#######
# sub git_status_of_file {
# my $self     = shift;
# my $main     = $self->main;
# my $document = $main->current->document;
# $self->git_cmd( 'status', $document->filename );
# return;
# }
#######
# git_status_of_dir
#######
# sub git_status_of_dir {
# my $self     = shift;
# my $main     = $self->main;
# my $document = $main->current->document;
# $self->git_cmd( 'status', File::Basename::dirname( $document->filename ) );
# return;
# }
#######
# git_status_of_project
#######
# sub git_status_of_project {
# my $self     = shift;
# my $main     = $self->main;
# my $document = $main->current->document;
# $self->git_cmd( 'status', $document->project_dir );
# return;
# }


#######
# git_diff_of_file
#######
# sub git_diff_of_file {
# my $self     = shift;
# my $main     = $self->main;
# my $document = $main->current->document;
# my $result   = $self->git_cmd( 'diff', $document->filename );
# if ( $result == 0 ) {
# $self->git_cmd( 'diff --cached', $document->filename );
# }
# return;
# }
#######
# git_diff_of_file_staged
#######
# sub git_diff_of_file_staged {
# my $self     = shift;
# my $main     = $self->main;
# my $document = $main->current->document;
# $self->git_cmd( 'diff --cached', $document->filename );
# return;
# }
#######
# git_diff_of_dir
#######
# sub git_diff_of_dir {
# my $self     = shift;
# my $main     = $self->main;
# my $document = $main->current->document;
# $self->git_cmd( 'diff', File::Basename::dirname( $document->filename ) );
# return;
# }
#######
# git_diff_of_project
#######
# sub git_diff_of_project {
# my $self     = shift;
# my $main     = $self->main;
# my $document = $main->current->document;
# $self->git_cmd( 'diff', $document->project_dir );
# return;
# }


#######
# git_log_stat
#######
# sub git_log_stat {
# my $self = shift;
# my $main = $self->main;
# $self->git_cmd( 'log --stat -2', '' );
# return;
# }
#######
# git_log_p
#######
# sub git_log_p {
# my $self = shift;
# my $main = $self->main;
# $self->git_cmd( 'log -p -2', '' );
# return;
# }
#######
# git_log_pretty
#######
# sub git_log_pretty {
# my $self = shift;
# my $main = $self->main;
# $self->git_cmd( 'log --pretty=format:"%h %s" --graph', '' );
# return;
# }


#######
# git_remote_show_origin
#######
# sub git_remote_show_origin {
# my $self = shift;
# $self->git_cmd_task( 'remote show origin', '' );
# return;
# }
#######
# git_remote_push_origin
#######
# sub git_remote_push_origin {
# my $self = shift;
# $self->git_cmd_task( 'push origin master', '' );
# return;
# }
#######
# git_remote_fetch_origin
#######
# sub git_remote_fetch_origin {
# my $self = shift;
# $self->git_cmd_task( 'fetch origin master', '' );
# return;
# }
#######
# git_remote_pull_origin
#######
# sub git_remote_pull_origin {
# my $self = shift;
# $self->git_cmd_task( 'pull origin master', '' );
# return;
# }
