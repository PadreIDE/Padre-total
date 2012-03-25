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

	# Setup preview editor
	my $preview = $self->{preview};
	require Padre::Document;
	$preview->{Document} = Padre::Document->new( mimetype => 'application/x-perl', );
	$preview->{Document}->set_editor($preview);
	$preview->SetLexer('application/x-perl');
	
	$preview->Show(1);

	return $self;
}

sub run {
	my $self    = shift;
	my $changes = shift;
	my $source = shift;

	# Apply the current theme to the preview editor
	my $preview = $self->{preview};
	my $style = $self->main->config->editor_style;
	my $theme = Padre::Wx::Theme->find($style)->clone;
	$theme->apply( $preview );
	
	$preview->SetText($$source);

	my $tree      = $self->{tree};
	my $root_node = $tree->AddRoot(
		Wx::gettext('Changes:'),
		-1,
		-1,

		#Wx::TreeItemData->new($program)
	);

	foreach my $change (@$changes) {
		my $change_node = $tree->AppendItem(
			$root_node,
			$change->{name},
			-1, -1,

			#Wx::TreeItemData->new($class)
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

1;

# Copyright 2008-2012 The Padre development team as listed in Padre.pm.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.
