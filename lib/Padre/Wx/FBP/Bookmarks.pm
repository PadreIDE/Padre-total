package Padre::Wx::FBP::Bookmarks;

## no critic

# This module was generated by Padre::Plugin::FormBuilder::Perl.
# To change this module, edit the original .fbp file and regenerate.
# DO NOT MODIFY BY HAND!

use 5.008;
use strict;
use warnings;
use Padre::Wx ();
use Padre::Wx::Role::Main ();

our $VERSION = '0.87';
our @ISA     = qw{
	Padre::Wx::Role::Main
	Wx::Dialog
};

sub new {
	my $class  = shift;
	my $parent = shift;

	my $self = $class->SUPER::new(
		$parent,
		-1,
		Wx::gettext("Bookmarks"),
		Wx::wxDefaultPosition,
		Wx::wxDefaultSize,
		Wx::wxDEFAULT_DIALOG_STYLE,
	);

	my $set_label = Wx::StaticText->new(
		$self,
		-1,
		Wx::gettext("Set Bookmark:"),
	);
	$set_label->Hide;

	my $set = Wx::TextCtrl->new(
		$self,
		-1,
		"",
		Wx::wxDefaultPosition,
		Wx::wxDefaultSize,
	);
	$set->Hide;

	my $set_line = Wx::StaticLine->new(
		$self,
		-1,
		Wx::wxDefaultPosition,
		Wx::wxDefaultSize,
		Wx::wxLI_HORIZONTAL,
	);
	$set_line->Hide;

	my $m_staticText2 = Wx::StaticText->new(
		$self,
		-1,
		Wx::gettext("Existing Bookmarks:"),
	);

	my $list = Wx::ListBox->new(
		$self,
		-1,
		Wx::wxDefaultPosition,
		Wx::wxDefaultSize,
		[],
		Wx::wxLB_NEEDED_SB | Wx::wxLB_SINGLE,
	);

	my $m_staticline1 = Wx::StaticLine->new(
		$self,
		-1,
		Wx::wxDefaultPosition,
		Wx::wxDefaultSize,
		Wx::wxLI_HORIZONTAL,
	);

	my $ok = Wx::Button->new(
		$self,
		Wx::wxID_OK,
		Wx::gettext("OK"),
	);
	$ok->SetDefault;

	my $delete = Wx::Button->new(
		$self,
		-1,
		Wx::gettext("&Delete"),
	);

	Wx::Event::EVT_BUTTON(
		$self,
		$delete,
		sub {
			shift->delete_clicked(@_);
		},
	);

	my $delete_all = Wx::Button->new(
		$self,
		-1,
		Wx::gettext("Delete &All"),
	);

	Wx::Event::EVT_BUTTON(
		$self,
		$delete_all,
		sub {
			shift->delete_all_clicked(@_);
		},
	);

	my $cancel = Wx::Button->new(
		$self,
		Wx::wxID_CANCEL,
		Wx::gettext("Cancel"),
	);

	my $existing = Wx::BoxSizer->new(Wx::wxHORIZONTAL);
	$existing->Add( $m_staticText2, 0, Wx::wxALL, 5 );

	my $buttons = Wx::BoxSizer->new(Wx::wxHORIZONTAL);
	$buttons->Add( $ok, 0, Wx::wxALL, 5 );
	$buttons->Add( $delete, 0, Wx::wxALL, 5 );
	$buttons->Add( $delete_all, 0, Wx::wxALL, 5 );
	$buttons->Add( 20, 0, 1, Wx::wxEXPAND, 5 );
	$buttons->Add( $cancel, 0, Wx::wxALL, 5 );

	my $vsizer = Wx::BoxSizer->new(Wx::wxVERTICAL);
	$vsizer->Add( $set_label, 0, Wx::wxALIGN_CENTER_VERTICAL | Wx::wxLEFT | Wx::wxRIGHT | Wx::wxTOP, 5 );
	$vsizer->Add( $set, 0, Wx::wxALL | Wx::wxEXPAND, 5 );
	$vsizer->Add( $set_line, 0, Wx::wxALL | Wx::wxEXPAND, 5 );
	$vsizer->Add( $existing, 1, Wx::wxEXPAND, 5 );
	$vsizer->Add( $list, 0, Wx::wxALL | Wx::wxEXPAND, 5 );
	$vsizer->Add( $m_staticline1, 0, Wx::wxALL | Wx::wxEXPAND, 5 );
	$vsizer->Add( $buttons, 0, Wx::wxEXPAND, 5 );

	my $sizer = Wx::BoxSizer->new(Wx::wxHORIZONTAL);
	$sizer->Add( $vsizer, 1, Wx::wxALL | Wx::wxEXPAND, 5 );

	$self->SetSizer($sizer);
	$self->Layout;
	$sizer->Fit($self);

	$self->{set_label} = $set_label->GetId;
	$self->{set} = $set->GetId;
	$self->{set_line} = $set_line->GetId;
	$self->{list} = $list->GetId;
	$self->{ok} = $ok->GetId;
	$self->{delete} = $delete->GetId;
	$self->{delete_all} = $delete_all->GetId;

	return $self;
}

sub set_label {
	Wx::Window::FindWindowById($_[0]->{set_label});
}

sub set {
	Wx::Window::FindWindowById($_[0]->{set});
}

sub set_line {
	Wx::Window::FindWindowById($_[0]->{set_line});
}

sub list {
	Wx::Window::FindWindowById($_[0]->{list});
}

sub ok {
	Wx::Window::FindWindowById($_[0]->{ok});
}

sub delete {
	Wx::Window::FindWindowById($_[0]->{delete});
}

sub delete_all {
	Wx::Window::FindWindowById($_[0]->{delete_all});
}

sub delete_clicked {
	$_[0]->main->error('Handler method delete_clicked for event delete.OnButtonClick not implemented');
}

sub delete_all_clicked {
	$_[0]->main->error('Handler method delete_all_clicked for event delete_all.OnButtonClick not implemented');
}

1;

# Copyright 2008-2011 The Padre development team as listed in Padre.pm.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.

