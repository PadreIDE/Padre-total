package Padre::Plugin::Git;

use 5.008;
use warnings;
use strict;

use Padre::Config ();
use Padre::Wx     ();
use Padre::Plugin ();
use Padre::Util   ();

use Capture::Tiny  qw(capture_merged);
use File::Basename ();
use File::Spec;

our $VERSION = '0.02';
our @ISA     = 'Padre::Plugin';

# TODO
# diff of file/dir/project
# commit of file/dir/project

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


#####################################################################
# Padre::Plugin Methods

sub padre_interfaces {
	'Padre::Plugin' => 0.24
}

sub plugin_name {
	'Git';
}



#####################################################################

# should be called once when loading the plugin
my $ONCE;
sub define_actions {
	my $self = shift;
	return if $ONCE;
	$ONCE = 1;
	Padre::Action->new(
		name        => 'git.about',
		label       => Wx::gettext('About'),
		comment     => Wx::gettext('Show information about the Git plugin'),
		need_editor => 0,
		menu_event  => sub {
			$self->show_about;
		},
	);

	Padre::Action->new(
		name        => 'git.commit_file',
		label       => Wx::gettext('Commit File'),
		comment     => Wx::gettext('Commit File'),
		need_editor => 0,
		menu_event  => sub {
			$self->git_commit_file;
		},
	);

	Padre::Action->new(
		name        => 'git.commit_project',
		label       => Wx::gettext('Commit Project'),
		comment     => Wx::gettext('Commit Project'),
		need_editor => 0,
		menu_event  => sub {
			$self->git_commit_file;
		},
	);

	Padre::Action->new(
		name        => 'git.status_of_file',
		label       => Wx::gettext('File Status'),
		comment     => Wx::gettext('Show the status of the current file'),
		need_editor => 0,
		menu_event  => sub {
			$self->git_status_of_file;
		},
	);

	Padre::Action->new(
		name        => 'git.status_of_dir',
		label       => Wx::gettext('Directory Status'),
		comment     => Wx::gettext('Show the status of the current directory'),
		need_editor => 0,
		menu_event  => sub {
			$self->git_status_of_dir;
		},
	);

	Padre::Action->new(
		name        => 'git.status_of_project',
		label       => Wx::gettext('Project Status'),
		comment     => Wx::gettext('Show the status of the current project'),
		need_editor => 0,
		menu_event  => sub {
			$self->git_status_of_project;
		},
	);

	Padre::Action->new(
		name        => 'git.diff_of_file',
		label       => Wx::gettext('Diff of File'),
		comment     => Wx::gettext('Diff of File'),
		need_editor => 0,
		menu_event  => sub {
			$self->git_diff_of_file;
		},
	);

	Padre::Action->new(
		name        => 'git.diff_of_dir',
		label       => Wx::gettext('Diff of Dir'),
		comment     => Wx::gettext('Diff of Dir'),
		need_editor => 0,
		menu_event  => sub {
			$self->git_diff_of_dir;
		},
	);

	Padre::Action->new(
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
		[
			'Commit...',
			'git.commit_file',
			'git.commit_project',
		],
		[
			'Status...',
			'git.status_of_file',
			'git.status_of_dir',
			'git.status_of_project',
		],

		[
			'Diff...',
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
	$about->SetVersion( $VERSION );

	# Show the About dialog
	Wx::AboutBox( $about );

	return;
}


sub git_commit {
	my ($self, $path) = @_;
	
	my $main = Padre->ide->wx->main;
	my $message = $main->prompt("Git Commit of $path", "Please type in your message", "MY_GIT_COMMIT");
	if ($message) {
		$main->message( $message, 'Filename' );
		system qq(git commit $path -m"$message");
	}

	return;	
}

sub git_commit_file {
	my ($self) = @_;

	my $main = Padre->ide->wx->main;
	my $doc = $main->current->document;
	my $filename = $doc->filename;
	$self->git_commit($filename);
	return;
}

sub git_commit_project {
	my ($self) = @_;

	my $main = Padre->ide->wx->main;
	my $doc = $main->current->document;
	my $filename = $doc->filename;
	my $dir = Padre::Util::get_project_dir($filename);
	$self->git_commit($dir);
	return;
}

sub git_status {
	my ($self, $path) = @_;

	my $main = Padre->ide->wx->main;
	my $out = capture_merged(sub { system "git status $path" });
	$main->message($out, "Git Status of $path");
	return;
}

sub git_status_of_file {
	my ($self) = @_;

#	return $main->error("No document found") if not $doc;
	$self->git_status(_get_current_filename());
	return;
}

sub git_status_of_dir {
	my ($self) = @_;

	my $main = Padre->ide->wx->main;
	my $doc = $main->current->document;
	return $main->error("No document found") if not $doc;
	my $filename = $doc->filename;
	$self->git_status(File::Basename::dirname($filename));

	return;
}

# TODO guess current project
sub git_status_of_project {
	my ($self) = @_;

	my $main = Padre->ide->wx->main;
	my $doc = $main->current->document;
	return $main->error("No document found") if not $doc;
	my $filename = $doc->filename;
	my $dir = Padre::Util::get_project_dir($filename);
	
	return $main->error("Could not find project root") if not $dir;
	
	$self->git_status($dir);

	return;
}

sub git_diff {
	my ($self, $path) = @_;

    use Cwd qw/cwd chdir/;
    my $cwd = cwd;
    chdir File::Basename::dirname($path);
	my $out = capture_merged(sub { system "git diff $path" });
	chdir $cwd;
	require Padre::Wx::Dialog::Text;
	my $main = Padre->ide->wx->main;
	Padre::Wx::Dialog::Text->show($main, "Git Diff of $path", $out);
#	$main->message($out, "Git Diff of $path");

	return;
}

sub git_diff_of_file {
	my ($self) = @_;

	$self->git_diff(_get_current_filename());

	return;
}

sub git_diff_of_dir {
	my ($self, $path) = @_;

	$self->git_diff($path);

    return;
}

sub git_diff_of_project {
	my ($self) = @_;
	
	my $main = Padre->ide->wx->main;
	my $doc = $main->current->document;
	return $main->error("No document found") if not $doc;
	my $filename = $doc->filename;
	my $dir = Padre::Util::get_project_dir($filename);
	
	return $main->error("Could not find project root") if not $dir;
	
	$self->git_diff($dir);

	return;
}

sub _get_current_filename {
	my $main = Padre->ide->wx->main;
	my $doc = $main->current->document;

	return $doc->filename;
}


sub _get_current_filedir {
	my $main = Padre->ide->wx->main;
	my $doc = $main->current->document;
	return $main->error("No document found") if not $doc;

	return File::Basename::dirname($doc->filename);
}

# This thing should just list a few actions
sub event_on_context_menu {
	my ( $self, $doc, $editor, $menu, $event ) = @_;

	# Same code for all VCS
	my $filename = $doc->filename;
	return if not $filename;

	my $project_dir = Padre::Util::get_project_dir($filename);
	return if not $project_dir;
	
	my $rcs = Padre::Util::get_project_rcs($project_dir);
	return if $rcs ne 'Git';

	$menu->AppendSeparator;
	my $menu_rcs = Wx::Menu->new;
	$menu->Append(-1, Wx::gettext('Git'), $menu_rcs);


	return;
}


1;

# Copyright 2008-2009 The Padre development team as listed in Padre.pm.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.

