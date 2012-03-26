package Padre::Plugin::Fix::Preview;

use Modern::Perl;
use Padre::Plugin::Fix::FBP::Preview ();

our $VERSION = '0.01';
our @ISA     = qw{
	Padre::Plugin::Fix::FBP::Preview
};

sub new {
	my $class  = shift;
	my $parent = shift;

	my $self = $class->SUPER::new($parent);
	$self->CenterOnParent;

	# Setup before/after editor
	$self->_setup_editor( $self->{before} );
	$self->_setup_editor( $self->{after} );

	return $self;
}

sub run {
	my $self    = shift;
	my $changes = shift;
	my $source  = shift;

	# Store for later usage
	$self->{changes} = $changes;
	$self->{source}  = $source;

	# Apply the current theme to the preview editors
	my $before = $self->{before};
	my $after  = $self->{after};
	$self->_apply_theme($before);
	$self->_apply_theme($after);

	$before->SetReadOnly(0);
	$before->SetText($$source);
	$before->SetReadOnly(1);
	$self->_apply_changes;

	my $tree = $self->{tree};
	my $root_node = $tree->AddRoot( Wx::gettext('Changes:'), -1, -1, );

	foreach my $change (@$changes) {
		my $change_node = $tree->AppendItem(
			$root_node, $change->{name}, -1, -1,
			Wx::TreeItemData->new($change)
		);

	}



	$tree->ExpandAll;

	if ( $self->ShowModal == Wx::ID_OK ) {
		say "OK";
	} else {
		say "Cancel";
	}

	return;
}

sub _apply_changes {
	my $self = shift;

	my $after = $self->{after};
	$after->SetReadOnly(0);
	$after->SetText( ${ $self->{source} } );
	for my $change ( @{ $self->{changes} } ) {

		$after->SetTargetStart( $change->{start} );
		$after->SetTargetEnd( $change->{end} );
		$after->ReplaceTarget( $change->{content} );
	}
	$after->SetReadOnly(1);

	return;
}

sub _setup_editor {
	my $self = shift;

	my $editor = shift;
	require Padre::Document;
	$editor->{Document} = Padre::Document->new( mimetype => 'application/x-perl', );
	$editor->{Document}->set_editor($editor);
	$editor->SetLexer('application/x-perl');
	$editor->Show(1);

	return;
}

sub _apply_theme {
	my $self   = shift;
	my $editor = shift;

	my $style = $self->main->config->editor_style;
	my $theme = Padre::Wx::Theme->find($style)->clone;
	$theme->apply($editor);

	return;
}

sub on_tree_selection_changed {
	my $self  = shift;
	my $event = shift;
	my $tree  = $self->{tree};
	my $item  = $event->GetItem or return;
	my $data  = $tree->GetPlData($item) or return;

	my $before = $self->{before};
	$before->GotoPos( $data->{start} );
	$before->SetSelection( $data->{start}, $data->{end} );

	my $after = $self->{after};
	$after->GotoPos( $data->{start} );
	$after->SetSelection( $data->{start}, $data->{end} );

	return;
}

1;

# Copyright 2008-2012 The Padre development team as listed in Padre.pm.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.
