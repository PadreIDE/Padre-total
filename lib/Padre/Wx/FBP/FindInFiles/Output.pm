package Padre::Wx::FBP::FindInFiles::Output;

## no critic

# This module was generated by Padre::Plugin::FormBuilder::Perl.
# To change this module edit the original .fbp file and regenerate.
# DO NOT MODIFY THIS FILE BY HAND!

use 5.008;
use strict;
use warnings;
use Padre::Wx ();
use Padre::Wx::Role::Main ();
use Padre::Wx::TreeCtrl ();

our $VERSION = '0.91';
our @ISA     = qw{
	Padre::Wx::Role::Main
	Wx::Panel
};

sub new {
	my $class  = shift;
	my $parent = shift;

	my $self = $class->SUPER::new(
		$parent,
		-1,
		Wx::DefaultPosition,
		[ 500, 300 ],
		Wx::TAB_TRAVERSAL,
	);

	$self->{repeat} = Wx::BitmapButton->new(
		$self,
		-1,
		Wx::NullBitmap,
		Wx::DefaultPosition,
		Wx::DefaultSize,
		Wx::BU_AUTODRAW,
	);

	Wx::Event::EVT_BUTTON(
		$self,
		$self->{repeat},
		sub {
			shift->on_repeat_click(@_);
		},
	);

	$self->{expand_all} = Wx::BitmapButton->new(
		$self,
		-1,
		Wx::NullBitmap,
		Wx::DefaultPosition,
		Wx::DefaultSize,
		Wx::BU_AUTODRAW,
	);

	Wx::Event::EVT_BUTTON(
		$self,
		$self->{expand_all},
		sub {
			shift->on_expand_all_click(@_);
		},
	);

	$self->{collapse_all} = Wx::BitmapButton->new(
		$self,
		-1,
		Wx::NullBitmap,
		Wx::DefaultPosition,
		Wx::DefaultSize,
		Wx::BU_AUTODRAW,
	);

	Wx::Event::EVT_BUTTON(
		$self,
		$self->{collapse_all},
		sub {
			shift->on_collapse_all_click(@_);
		},
	);

	$self->{tree} = Padre::Wx::TreeCtrl->new(
		$self,
		-1,
		Wx::DefaultPosition,
		Wx::DefaultSize,
		Wx::TR_FULL_ROW_HIGHLIGHT | Wx::TR_HAS_BUTTONS | Wx::TR_SINGLE,
	);

	Wx::Event::EVT_TREE_ITEM_ACTIVATED(
		$self,
		$self->{tree},
		sub {
			shift->on_find_result_clicked(@_);
		},
	);

	my $button_sizer = Wx::BoxSizer->new(Wx::HORIZONTAL);
	$button_sizer->Add( $self->{repeat}, 0, Wx::ALL, 2 );
	$button_sizer->Add( $self->{expand_all}, 0, Wx::ALL, 2 );
	$button_sizer->Add( $self->{collapse_all}, 0, Wx::ALL, 2 );

	my $main_sizer = Wx::BoxSizer->new(Wx::VERTICAL);
	$main_sizer->Add( $button_sizer, 0, Wx::ALIGN_RIGHT, 2 );
	$main_sizer->Add( $self->{tree}, 1, Wx::ALL | Wx::EXPAND, 2 );

	$self->SetSizer($main_sizer);
	$self->Layout;

	return $self;
}

sub on_repeat_click {
	$_[0]->main->error('Handler method on_repeat_click for event repeat.OnButtonClick not implemented');
}

sub on_expand_all_click {
	$_[0]->main->error('Handler method on_expand_all_click for event expand_all.OnButtonClick not implemented');
}

sub on_collapse_all_click {
	$_[0]->main->error('Handler method on_collapse_all_click for event collapse_all.OnButtonClick not implemented');
}

sub on_find_result_clicked {
	$_[0]->main->error('Handler method on_find_result_clicked for event tree.OnTreeItemActivated not implemented');
}

1;

# Copyright 2008-2011 The Padre development team as listed in Padre.pm.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.

