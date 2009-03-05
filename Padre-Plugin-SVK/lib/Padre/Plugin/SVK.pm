package Padre::Plugin::SVK;

use 5.008;
use warnings;
use strict;

use Padre::Config ();
use Padre::Wx     ();
use Padre::Plugin ();

use Capture::Tiny  qw(capture_merged);
use File::Basename ();
use File::Spec;

our $VERSION = '0.02';
our @ISA     = 'Padre::Plugin';

# TODO
# diff of file/dir/project
# commit of file/dir/project


=head1 NAME

Padre::Plugin::SVK - Simple SVK interface for Padre

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

cpan install Padre::Plugin::SVK

Acces it via Plugin/SVK


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
	'SVK';
}

sub menu_plugins_simple {
	my $self = shift;
	return $self->plugin_name => [
		'About' => sub { $self->show_about },
		'Commit' => sub { $self->svk_commit },
		'Status of File' => sub { $self->svk_status_of_file },
		'Status of Dir' => sub { $self->svk_status_of_dir },
		'Status of Project' => sub { $self->svk_status_of_project },
	];
}



#####################################################################
# Custom Methods

sub show_about {
	my $self = shift;

	# Generate the About dialog
	my $about = Wx::AboutDialogInfo->new;
	$about->SetName("Padre::Plugin::SVK");
	$about->SetDescription( <<"END_MESSAGE" );
Initial SVK support for Padre
END_MESSAGE
	$about->SetVersion( $VERSION );

	# Show the About dialog
	Wx::AboutBox( $about );

	return;
}


sub svk_commit {
	my ($self) = @_;
	
	my $main = Padre->ide->wx->main;
	my $doc = $main->current->document;
	my $filename = $doc->filename;
	$main->message( "Count: $filename", 'Filename' );

	my $message = $main->prompt("SVK Commit of $filename", "Please type in your message", "MY_SVK_COMMIT");
	if ($message) {
		$main->message( $message, 'Filename' );
		system qq(svk commit $filename -m"$message");
	}


	return;	
}

sub svk_status {
	my ($self, $path) = @_;
	
	my $main = Padre->ide->wx->main;
	my $out = capture_merged(sub { system "svk status $path" });
	$main->message($out, "SVK Status of $path");
	return;
}
sub svk_status_of_file {
	my ($self) = @_;
	
	my $main = Padre->ide->wx->main;
	my $doc = $main->current->document;
	return $main->error("No document found") if not $doc;
	$self->svk_status($doc->filename);
	return;
}
sub svk_status_of_dir {
	my ($self) = @_;
	
	my $main = Padre->ide->wx->main;
	my $doc = $main->current->document;
	return $main->error("No document found") if not $doc;
	my $filename = $doc->filename;
	$self->svk_status(File::Basename::dirname($filename));

	return;
}

# TODO guess current project
sub svk_status_of_project {
	my ($self) = @_;
	
	my $main = Padre->ide->wx->main;
	my $doc = $main->current->document;
	return $main->error("No document found") if not $doc;
	my $filename = $doc->filename;
	return $main->error("File type not yet supported") if not $filename =~ /\.pm$/;
	my $olddir = File::Basename::dirname($filename);
	my $dir    = File::Basename::dirname($olddir);
	print "DIR: $olddir\n     $dir\n";
	while (1) {
		last if $olddir eq $dir;
		last if -e File::Spec->catfile($dir, 'Makefile.PL');
		last if -e File::Spec->catfile($dir, 'Build.PL');
		print "trying $dir\n";
		$olddir = $dir;
		$dir = File::Basename::dirname($dir);
	}
	return $main->error("Could not find project root") if $dir eq $olddir;	
	$self->svk_status($dir);

	return;
}


1;

# Copyright 2008-2009 The Padre development team as listed in Padre.pm.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.

