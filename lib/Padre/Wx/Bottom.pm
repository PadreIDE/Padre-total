package Padre::Wx::Bottom;

# The bottom notebook

use strict;
use warnings;
use Padre::Constant            ();
use Padre::Wx                  ();
use Padre::Wx::Role::MainChild ();

our $VERSION = '0.40';
our @ISA     = qw{
	Padre::Wx::Role::MainChild
	Wx::AuiNotebook
};

sub new {
	my $class = shift;
	my $main  = shift;
	my $aui   = $main->aui;

	# Create the basic object
	my $self = $class->SUPER::new(
		$main,
		-1,
		Wx::wxDefaultPosition,

		# Used when pane is floated
		Wx::Size->new( 350, 300 ),
		Wx::wxAUI_NB_SCROLL_BUTTONS
			| Wx::wxAUI_NB_TOP
			| Wx::wxBORDER_NONE,
	);

	# Add ourself to the window manager
	$aui->AddPane(
		$self,
		Wx::AuiPaneInfo->new->Name('bottom')->Resizable(1)->PaneBorder(0)->Movable(1)->CaptionVisible(1)->CloseButton(0)
			->DestroyOnClose(0)->MaximizeButton(1)->Floatable(1)->Dockable(1)->Position(2)->Bottom->Layer(4)->Hide
	);

	# Set the locale-aware caption
	$aui->caption( 'bottom' => Wx::gettext('Output View') );

	return $self;
}

sub aui {
	$_[0]->GetParent->aui;
}

#####################################################################
# Page Management

sub show {
	my $self = shift;
	my $page = shift;

	# Are we currently showing the page
	my $position = $self->GetPageIndex($page);
	if ( $position >= 0 ) {

		# Already showing, switch to it
		$self->SetSelection($position);
		return;
	}

	# Add the page
	$self->InsertPage(
		0,
		$page,
		$page->gettext_label,
		1,
	);
	$page->Show;
	$self->Show;
	$self->aui->GetPane($self)->Show;

	return;
}

sub hide {
	my $self     = shift;
	my $page     = shift;
	my $position = $self->GetPageIndex($page);
	unless ( $position >= 0 ) {

		# Not showing this
		return 1;
	}

	# Remove the page
	$page->Hide;
	$self->RemovePage($position);

	# Is this the last page?
	if ( $self->GetPageCount == 0 ) {
		$self->Hide;
		$self->aui->GetPane($self)->Hide;
	}

	return;
}

sub relocale {
	my $self = shift;
	foreach my $i ( 0 .. $self->GetPageCount - 1 ) {
		$self->SetPageText( $i, $self->GetPage($i)->gettext_label );
	}
}

1;

# Copyright 2008-2009 The Padre development team as listed in Padre.pm.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.
