package Padre::Plugin::SVN;

use 5.008;
use warnings;
use strict;

use Padre::Config ();
use Padre::Wx     ();
use Padre::Plugin ();
use Padre::Util   ();

#use Capture::Tiny  qw(capture_merged);
#use File::Basename ();
#use File::Spec;

#use VCI;

our $VERSION = '0.01';
our @ISA     = 'Padre::Plugin';



=head1 NAME

Padre::Plugin::SVN - Simple SVN interface for Padre

=head1 SYNOPSIS

cpan install Padre::Plugin::SVN

Acces it via Plugin/SVN


=head1 AUTHOR

Gabor Szabo, C<< <szabgab at gmail.com> >>

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
	'SVN';
}

sub menu_plugins_simple {
	my $self = shift;
	return $self->plugin_name => [
		'About'             => sub { $self->show_about },
		'Commit...' => [
			'File'     => sub { $self->svn_commit_file },
			'Project'  => sub { $self->svn_commit_project },
		],
		'Status...' => [
			'File'    => sub { $self->svn_status_of_file },
			'Project' => sub { $self->svn_status_of_project },
		],
		'Diff...' => [
			'File'    => sub { $self->svn_diff_of_file },
			'Dir'     => sub { $self->svn_diff_of_dir },
			'Project' => sub { $self->svn_diff_of_project },
		],
	];
}

#####################################################################
# Custom Methods

sub show_about {
	my $self = shift;

	# Generate the About dialog
	my $about = Wx::AboutDialogInfo->new;
	$about->SetName("Padre::Plugin::SVN");
	$about->SetDescription( <<"END_MESSAGE" );
Initial SVN support for Padre
END_MESSAGE
	$about->SetVersion( $VERSION );

	# Show the About dialog
	Wx::AboutBox( $about );

	return;
}

sub svn_status {
	my ($self, $path) = @_;
	my $main = Padre->ide->wx->main;
	my $status = qx{svn status $path};
	$main->message($status, "$path");
	return;
}
sub svn_status_of_file {
	my ($self) = @_;
	
	my $main = Padre->ide->wx->main;
	my $doc = $main->current->document;
	my $filename = $doc->filename;
	$self->svn_status($filename);
	return;
}
sub svn_status_of_project {
	my ($self) = @_;
	
	my $main = Padre->ide->wx->main;
	my $doc = $main->current->document;
	my $filename = $doc->filename;
	my $dir = Padre::Util::get_project_dir($filename);
	$self->svn_status($dir);
	return;
}


sub svn_diff {
	my ($self, $path) = @_;
	my $main = Padre->ide->wx->main;
	my $status = qx{svn diff $path};
	$main->message($status, "$path");
	return;
}
sub svn_diff_of_file {
	my ($self) = @_;
	
	my $main = Padre->ide->wx->main;
	my $doc = $main->current->document;
	my $filename = $doc->filename;
	$self->svn_diff($filename);
	return;
}

sub svn_diff_of_project {
	my ($self) = @_;
	
	my $main = Padre->ide->wx->main;
	my $doc = $main->current->document;
	my $filename = $doc->filename;
	my $dir = Padre::Util::get_project_dir($filename);
	$self->svn_diff($dir);
	return;
}

sub svn_commit {
	my ($self, $path) = @_;
	
	my $main = Padre->ide->wx->main;
	my $message = $main->prompt("SVN Commit of $path", "Please type in your message", "MY_SVN_COMMIT");
	if ($message) {
		$main->message( $message, 'Filename' );
		system qq(svn commit $path -m"$message");
	}

	return;	
}

sub svn_commit_file {
	my ($self) = @_;
	
	my $main = Padre->ide->wx->main;
	my $doc = $main->current->document;
	my $filename = $doc->filename;
	$self->svn_commit($filename);
	return;
}

sub svn_commit_project {
	my ($self) = @_;
	
	my $main = Padre->ide->wx->main;
	my $doc = $main->current->document;
	my $filename = $doc->filename;
	my $dir = Padre::Util::get_project_dir($filename);
	$self->svn_commit($dir);
	return;
}


#sub vci {
#	my ($self, $path) = @_;
#	my $main = Padre->ide->wx->main;
#	# TODO: connect to SVN repo without this workaround
#	my @info = qx{svn info $path};
#	if (not @info) {
#		$main->error("$path does not seem to be under SVN");
#		return;
#	}
#	chomp @info;
#	my ($repo) = grep { $_ =~ /^Repository Root: / } @info;
#	$repo =~ s/^Repository Root:\s*//; 
#	$main->message("'$repo'", "File");
#	my $repository = VCI->connect(type => 'Svn', repo => $repo);
#	print "$repository\n";
#	print "---\n";
#	print $repository->projects, "\n";
#
#	return;
#}
#

1;


