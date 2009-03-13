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

our $VERSION = '0.01';
our @ISA     = 'Padre::Plugin';

# TODO
# diff of file/dir/project
# commit of file/dir/project

=head1 NAME

Padre::Plugin::Git - Simple Git interface for Padre

=head1 SYNOPSIS

cpan install Padre::Plugin::Git

Acces it via Plugin/Git


=head1 AUTHOR

Kaare Rasmussen, C<< <kaare at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to L<http://padre.perlide.org/>


=head1 COPYRIGHT & LICENSE

Copyright 2008-2009 The Padre development team as listed in Padre.pm.
all rights reserved.

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

sub menu_plugins_simple {
	my $self = shift;
	return $self->plugin_name => [
		'About'             => sub { $self->show_about },
		'Commit...' => [
			'File'     => sub { $self->git_commit_file },
			'Project'  => sub { $self->git_commit_project },
		],
		'Status...' => [
			'File'    => sub { $self->git_status_of_file },
			'Dir'     => sub { $self->git_status_of_dir },
			'Project' => sub { $self->git_status_of_project },
		],
		'Diff...' => [
			'File'    => sub { $self->git_diff_of_file },
			'Dir'     => sub { $self->git_diff_of_dir },
			'Project' => sub { $self->git_diff_of_project },
		],
	];
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
	
	my $main = Padre->ide->wx->main;
	my $doc = $main->current->document;
	return $main->error("No document found") if not $doc;
	$self->git_status($doc->filename);
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
	
	my $main = Padre->ide->wx->main;
	my $out = capture_merged(sub { system "git diff $path" });
	use Padre::Wx::Dialog::Text;
	Padre::Wx::Dialog::Text->show($main, "Git Diff of $path", $out);
#	$main->message($out, "Git Diff of $path");
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

1;

# Copyright 2008-2009 The Padre development team as listed in Padre.pm.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.

