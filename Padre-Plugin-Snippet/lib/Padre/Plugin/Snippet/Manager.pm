package Padre::Plugin::Snippet::Manager;

use 5.008;
use Moose;
use Padre::Wx::Role::Dialog              ();
use Padre::Plugin::Snippet::FBP::Manager ();

our $VERSION = '0.20';
our @ISA     = qw{
	Padre::Wx::Role::Dialog
	Padre::Plugin::Snippet::FBP::Manager
};

sub new {
	my $class  = shift;
	my $plugin = shift;


	my $self = $class->SUPER::new( $plugin->main );

	# Store the plugin object for future usage
	$self->{plugin} = $plugin;

	# Center & title
	$self->CenterOnParent;
	$self->SetTitle(
		sprintf( Wx::gettext('Moose Assistant %s - Written for fun by Ahmad M. Zawawi (azawawi)'), $VERSION ) );

	return $self;
}

# This is called to start and show the dialog
sub run {
	my $self = shift;

	# # Apply the current theme to the preview editor
	# my $style = $self->main->config->editor_style;
	# my $theme = Padre::Wx::Theme->find($style)->clone;
	# $theme->apply( $self->{preview} );

	$self->ShowModal;
}

1;

# Copyright 2008-2012 The Padre development team as listed in Padre.pm.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.
