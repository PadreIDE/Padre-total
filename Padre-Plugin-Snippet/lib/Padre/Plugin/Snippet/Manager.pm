package Padre::Plugin::Snippet::Manager;

use 5.008;
use Moose;
use Padre::Wx::Role::Dialog              ();
use Padre::Plugin::Snippet::FBP::Manager ();

our $VERSION = '0.01';
our @ISA     = qw{
	Padre::Wx::Role::Dialog
	Padre::Plugin::Snippet::FBP::Manager
};

sub new {
	my $class           = shift;
	my $plugin          = shift;
	my $snippet_bundles = shift;

	my $self = $class->SUPER::new( $plugin->main );

	# Store state
	$self->{plugin}          = $plugin;
	$self->{snippet_bundles} = $snippet_bundles;

	# Center & title
	$self->CenterOnParent;
	$self->SetTitle(
		sprintf( Wx::gettext('Snippet Manager %s - Written for fun by Ahmad M. Zawawi (azawawi)'), $VERSION ) );

	# Create snippet editor
	my $editor = $self->{snippet_editor};
	require Padre::Document;
	my $mimetype = 'text/plain';
	$editor->{Document} = Padre::Document->new( mimetype => $mimetype );
	$editor->{Document}->set_editor($editor);
	$editor->SetLexer($mimetype);
	$editor->Show(1);

	# Add images to add/delete bitmap buttons
	$self->{add_button}->SetBitmapLabel( Padre::Wx::Icon::find('actions/list-add') );
	$self->{delete_button}->SetBitmapLabel( Padre::Wx::Icon::find('actions/list-remove') );

	$self->_populate_tree;

	return $self;
}

# This is called to start and show the dialog
sub run {
	my $self = shift;

	# Apply the current theme to the snippet editor
	my $style = $self->main->config->editor_style;
	my $theme = Padre::Wx::Theme->find($style)->clone;
	$theme->apply( $self->{snippet_editor} );

	$self->ShowModal;
}

sub _populate_tree {
	my $self = shift;

	my $snippet_bundles = $self->{snippet_bundles};
	my $tree            = $self->{tree};
	my $root_node       = $tree->AddRoot(
		Wx::gettext('...'),
		-1,
		-1,
	);

	foreach my $bundle_id ( sort keys %{$snippet_bundles} ) {
		my $bundle      = $snippet_bundles->{$bundle_id};
		my $bundle_node = $tree->AppendItem(
			$root_node,
			$bundle->{name},
			-1, -1,
			Wx::TreeItemData->new($bundle)
		);

		foreach my $trigger ( keys %{ $bundle->{snippets} } ) {
			my $snippet_item = $tree->AppendItem(
				$bundle_node,
				$trigger,
				-1, -1,

				Wx::TreeItemData->new(
					{   trigger => $trigger,
						snippet => $bundle->{snippets}->{$trigger},
					}
				)
			);
		}

		$tree->Expand($bundle_node);
	}
	$tree->Expand($root_node);

	return;
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

sub on_tree_selection_change {
	my $self    = shift;
	my $event   = shift;
	my $tree    = $self->{tree};
	my $item    = $event->GetItem or return;
	my $element = $tree->GetPlData($item) or return;

	if ( defined $element->{trigger} ) {
		$self->{trigger_text}->SetValue( $element->{trigger} );
		$self->{snippet_editor}->SetText( $element->{snippet} );
	} else {
		$self->{trigger_text}->SetValue('');
		$self->{snippet_editor}->SetText('');
	}

	return;
}


1;

# Copyright 2008-2012 The Padre development team as listed in Padre.pm.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.
