package Padre::Plugin::Media;

use 5.008;
use strict;
use warnings;
use File::ShareDir ();
use Padre::Config  ();
use Padre::Wx      ();
use Padre::Plugin  ();

our $VERSION = '0.25';
our @ISA     = 'Padre::Plugin';





#####################################################################
# Padre::Plugin Methods

sub padre_interfaces {
	'Padre::Plugin' => '0.91';
}

sub plugin_name {
	'Media Plugin';
}

sub menu_plugins_simple {
	my $self = shift;
	return $self->plugin_name => [
		'About' => sub { $self->show_about },

		# 'Another Menu Entry' => sub { $self->about },
		# 'A Sub-Menu...' => [
		#     'Sub-Menu Entry' => sub { $self->about },
		# ],
	];
}





#####################################################################
# Custom Methods

sub show_about {
	my $self = shift;

	# Find the audio file
	my $file = File::ShareDir::dist_file(
		'Padre-Plugin-Media',
		'cartman_03.wav',
	);
	$file = '' unless -f $file;

	# Attempt to play the file
	if ($file) {
		my $wave = Wx::Sound->new($file);
		$wave->Play( Wx::wxSOUND_ASYNC() );
	}

	# Generate the About dialog
	my $about = Wx::AboutDialogInfo->new;
	$about->SetName("My Plugin");
	$about->SetDescription( <<"END_MESSAGE" );
A plugin for testing media support

File = '$file'

END_MESSAGE

	# Show the About dialog
	Wx::AboutBox($about);

	return;
}

1;

# Copyright 2008 Gabor Szabo.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.
