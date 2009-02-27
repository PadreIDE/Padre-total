package Padre::Plugin::SVK;

use 5.008;
use warnings;
use strict;

use Padre::Config ();
use Padre::Wx     ();
use Padre::Plugin ();

use Capture::Tiny qw(capture_merged);

our $VERSION = '0.01';
our @ISA     = 'Padre::Plugin';

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
		'Status' => sub { $self->svk_status },
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
	my ($self) = @_;
	
	my $main = Padre->ide->wx->main;
	my $doc = $main->current->document;
	my $filename = $doc->filename;
	my $out = capture_merged(sub { system "svk status $filename" });
	$main->message($out, "SVK Status of $filename");
	return;
}

1;

# Copyright 2008-2009 The Padre development team as listed in Padre.pm.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.

