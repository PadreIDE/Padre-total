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

use Capture::Tiny qw(capture_merged);
use File::Basename ();
use File::Spec;
use Cwd qw(cwd chdir);

our $VERSION = '0.04';
use parent qw(Padre::Plugin);

# use Data::Printer { caller_info => 1, colored => 1, };

# TODO
# diff of file/dir/project
# commit of file/dir/project





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


#####################################################################

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
			$self->git_commit_file;
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


#####################################################################
# Custom Methods

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


sub git_commit {
	my ( $self, $path ) = @_;

	my $main = Padre->ide->wx->main;
	my $message = $main->prompt( "Git Commit of $path", "Please type in your message", "MY_GIT_COMMIT" );
	if ($message) {
		$main->message( $message, 'Filename' );
		my $cwd = cwd;
		chdir File::Basename::dirname($path);
		system qq(git commit $path -m"$message");
		chdir $cwd;
	}

	return;
}

sub git_commit_file {
	my ($self) = @_;

	my $main     = Padre->ide->wx->main;
	my $document = $main->current->document;
	my $filename = $document->filename;
	$self->git_commit($filename);
	return;
}

sub git_commit_project {
	my ($self) = @_;

	my $main     = Padre->ide->wx->main;
	my $document = $main->current->document;
	my $filename = $document->filename;
	my $dir      = $document->project_dir;
	$self->git_commit($dir);
	return;
}

###################
#

#######
# git_status
#######
sub git_status {
	my $self     = shift;
	my $path     = shift;
	my $main     = $self->main;
	my $document = $main->current->document;

	require Padre::Util;
	my $git_status =
		Padre::Util::run_in_directory_two( cmd => "git status $path", dir => $document->project_dir, option => 0 );

	#strip leading #
	$git_status->{output} =~ s/^(\#)//sxmg;

	$main->message(
		sprintf(
			Wx::gettext("Git Status of -> %s \n\n%s"),
			$path, $git_status->{output}
		),
	);

	return;
}

#######
# git_status_of_file
#######
sub git_status_of_file {
	my $self     = shift;
	my $main     = $self->main;
	my $document = $main->current->document;

	return $main->error("No document found") if not $document;
	$self->git_status( $document->filename );
	return;
}

#######
# git_status_of_dir
#######
sub git_status_of_dir {
	my $self     = shift;
	my $main     = $self->main;
	my $document = $main->current->document;

	return $main->error("No document found") if not $document;
	$self->git_status( File::Basename::dirname( $document->filename ) );
	return;
}

#######
# git_status_of_project
#######
sub git_status_of_project {
	my $self     = shift;
	my $main     = $self->main;
	my $document = $main->current->document;

	return $main->error("No document found") if not $document;
	my $filename = $document->filename;

	my $dir = $document->project_dir;
	return $main->error("Could not find project root") if not $dir;

	$self->git_status($dir);
	return;
}

#
##################




sub git_diff {
	my ( $self, $path ) = @_;

	use Cwd qw/cwd chdir/;
	my $cwd = cwd;
	chdir File::Basename::dirname($path);
	my $out = capture_merged( sub { system "git diff $path" } );
	chdir $cwd;
	require Padre::Wx::Dialog::Text;
	my $main = Padre->ide->wx->main;
	Padre::Wx::Dialog::Text->show( $main, "Git Diff of $path", $out );

	#	$main->message($out, "Git Diff of $path");

	return;
}

sub git_diff_of_file {
	my ($self) = @_;

	p _get_current_filename();

	$self->git_diff( _get_current_filename() );

	return;
}

sub git_diff_of_dir {
	my ( $self, $path ) = @_;

	$self->git_diff($path);

	return;
}

sub git_diff_of_project {
	my $self     = shift;
	my $main     = $self->main;
	my $document = $main->current->document;
	return $main->error("No document found") if not $document;
	my $filename = $document->filename;
	my $dir      = $document->project_dir;

	return $main->error("Could not find project root") if not $dir;

	$self->git_diff($dir);

	return;
}

#ToDo delete this asap
sub _get_current_filename {
	my $main     = Padre->ide->wx->main;
	my $document = $main->current->document;

	return $document->filename;
}

#ToDo delete this asap
sub _get_current_filedir {
	my $main = Padre->ide->wx->main;

	my $document = $main->current->document;
	return $main->error("No document found") if not $document;

	return File::Basename::dirname( $document->filename );
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
		my $menu_rcs = $self->menu_actions;
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

1;

__END__

=head1 NAME

Padre::Plugin::Git - Simple Git interface for Padre

=head1 SYNOPSIS

cpan install Padre::Plugin::Git

Access it via Plugin/Git


=head1 AUTHOR

Kaare Rasmussen, C<< <kaare at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to L<http://padre.perlide.org/>


=head1 COPYRIGHT & LICENSE

Copyright 2008-2009 The Padre development team as listed in Padre.pm in the
Padre distribution all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

# Copyright 2008-2009 The Padre development team as listed in Padre.pm.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.


