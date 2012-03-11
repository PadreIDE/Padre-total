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
		sprintf( Wx::gettext('Snippet Manager %s - Written for fun by Ahmad M. Zawawi (azawawi)'), $VERSION ) );

	# Create snippet editor
	my $snippet_editor = $self->{snippet_editor};
	require Padre::Document;
	my $mimetype = 'text/plain';
	$snippet_editor->{Document} = Padre::Document->new( mimetype => $mimetype );
	$snippet_editor->{Document}->set_editor($snippet_editor);
	$snippet_editor->SetLexer($mimetype);
	$snippet_editor->Show(1);

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

sub on_prefs_button_clicked {
	my $self = shift;

	# Create a new preferences dialog
	require Padre::Plugin::Snippet::Preferences;
	my $prefs = Padre::Plugin::Snippet::Preferences->new($self);

	# Update plugin variables from plugin's configuration hash
	my $plugin = $self->{plugin};
	my $config = $plugin->{config};
	$prefs->{snippets_checkbox}->SetValue( $config->{feature_snippets} );

	# Preferences: go modal!
	if ( $prefs->ShowModal == Wx::wxID_OK ) {

		# Update configuration when the user hits the OK button
		$config->{feature_snippets} = $prefs->{snippets_checkbox}->IsChecked;
		$plugin->config_write($config);
	}

	return;
}

1;

# Copyright 2008-2012 The Padre development team as listed in Padre.pm.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.
