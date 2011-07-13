package Padre::Plugin::Cookbook::Recipe04::FBP::MainFB;

## no critic

# This module was generated by Padre::Plugin::FormBuilder::Perl.
# To change this module edit the original .fbp file and regenerate.
# DO NOT MODIFY THIS FILE BY HAND!

use 5.008;
use strict;
use warnings;
use Padre::Wx ();
use Padre::Wx::Role::Main ();

our $VERSION = '0.22';
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
		Wx::gettext("Main"),
		Wx::wxDefaultPosition,
		Wx::wxDefaultSize,
		Wx::wxDEFAULT_DIALOG_STYLE | Wx::wxRESIZE_BORDER,
	);
	$self->SetSizeHints( Wx::wxDefaultSize, Wx::wxDefaultSize );

	my $package_name = Wx::StaticText->new(
		$self,
		-1,
		Wx::gettext("ConfigDB"),
	);
	$package_name->SetFont(
		Wx::Font->new( 14, 70, 90, 92, 0, "" )
	);

	my $relation_title = Wx::StaticText->new(
		$self,
		-1,
		Wx::gettext("Relation Name"),
	);
	$relation_title->SetFont(
		Wx::Font->new( 14, 70, 90, 90, 0, "" )
	);

	my $display_cardinality = Wx::StaticText->new(
		$self,
		-1,
		Wx::gettext("Cardinality"),
	);

	my $about = Wx::Button->new(
		$self,
		-1,
		Wx::gettext("About"),
		Wx::wxDefaultPosition,
		Wx::wxDefaultSize,
	);

	Wx::Event::EVT_BUTTON(
		$self,
		$about,
		sub {
			shift->about_clicked(@_);
		},
	);

	my $m_staticline1_1 = Wx::StaticLine->new(
		$self,
		-1,
		Wx::wxDefaultPosition,
		Wx::wxDefaultSize,
		Wx::wxLI_HORIZONTAL,
	);

	my $list_ctrl = Wx::ListCtrl->new(
		$self,
		-1,
		Wx::wxDefaultPosition,
		Wx::wxDefaultSize,
		Wx::wxLC_EDIT_LABELS | Wx::wxLC_REPORT,
	);
	$list_ctrl->SetMinSize( [ 560, 188 ] );

	Wx::Event::EVT_LIST_COL_CLICK(
		$self,
		$list_ctrl,
		sub {
			shift->_on_list_col_clicked(@_);
		},
	);

	Wx::Event::EVT_LIST_ITEM_ACTIVATED(
		$self,
		$list_ctrl,
		sub {
			shift->_on_list_item_activated(@_);
		},
	);

	my $m_staticline1_2 = Wx::StaticLine->new(
		$self,
		-1,
		Wx::wxDefaultPosition,
		Wx::wxDefaultSize,
		Wx::wxLI_HORIZONTAL,
	);

	my $m_staticText5 = Wx::StaticText->new(
		$self,
		-1,
		Wx::gettext("config.db"),
	);
	$m_staticText5->SetFont(
		Wx::Font->new( Wx::wxNORMAL_FONT->GetPointSize, 70, 90, 92, 0, "" )
	);

	my $relations = Wx::RadioBox->new(
		$self,
		-1,
		Wx::gettext("Relations"),
		Wx::wxDefaultPosition,
		Wx::wxDefaultSize,
		[
			"Plugin",
			"Session",
			"SessionFile",
			"Bookmark",
			"History",
			"HostConfig",
			"Snippets",
			"RecentlyUsed",
			"SyntaxHighlight",
			"LastPositionInFile",
		],
		2,
		Wx::wxRA_SPECIFY_ROWS,
	);
	$relations->SetSelection(0);

	my $m_staticline1_3 = Wx::StaticLine->new(
		$self,
		-1,
		Wx::wxDefaultPosition,
		Wx::wxDefaultSize,
		Wx::wxLI_HORIZONTAL,
	);

	my $update = Wx::Button->new(
		$self,
		-1,
		Wx::gettext("Update"),
		Wx::wxDefaultPosition,
		Wx::wxDefaultSize,
	);

	Wx::Event::EVT_BUTTON(
		$self,
		$update,
		sub {
			shift->update_clicked(@_);
		},
	);

	my $show = Wx::Button->new(
		$self,
		-1,
		Wx::gettext("Show"),
		Wx::wxDefaultPosition,
		Wx::wxDefaultSize,
	);
	$show->Disable;

	Wx::Event::EVT_BUTTON(
		$self,
		$show,
		sub {
			shift->show_clicked(@_);
		},
	);

	my $clean = Wx::Button->new(
		$self,
		-1,
		Wx::gettext("Clean"),
		Wx::wxDefaultPosition,
		Wx::wxDefaultSize,
	);
	$clean->Disable;

	Wx::Event::EVT_BUTTON(
		$self,
		$clean,
		sub {
			shift->clean_clicked(@_);
		},
	);

	my $width_ajust = Wx::Button->new(
		$self,
		-1,
		Wx::gettext("Ajust Width"),
		Wx::wxDefaultPosition,
		Wx::wxDefaultSize,
	);
	$width_ajust->Disable;

	Wx::Event::EVT_BUTTON(
		$self,
		$width_ajust,
		sub {
			shift->width_ajust_clicked(@_);
		},
	);

	my $close_button = Wx::Button->new(
		$self,
		Wx::wxID_CANCEL,
		Wx::gettext("Close"),
		Wx::wxDefaultPosition,
		Wx::wxDefaultSize,
	);
	$close_button->SetDefault;

	my $bSizer6 = Wx::BoxSizer->new(Wx::wxVERTICAL);
	$bSizer6->Add( $relation_title, 0, Wx::wxALL, 5 );
	$bSizer6->Add( $display_cardinality, 0, Wx::wxALL, 5 );

	my $bSizer1 = Wx::BoxSizer->new(Wx::wxHORIZONTAL);
	$bSizer1->Add( $package_name, 0, Wx::wxALL, 5 );
	$bSizer1->Add( 0, 0, 1, Wx::wxEXPAND, 5 );
	$bSizer1->Add( $bSizer6, 1, Wx::wxEXPAND, 5 );
	$bSizer1->Add( 0, 0, 1, Wx::wxEXPAND, 5 );
	$bSizer1->Add( $about, 0, Wx::wxALL, 5 );

	my $bSizer5 = Wx::BoxSizer->new(Wx::wxHORIZONTAL);
	$bSizer5->Add( $list_ctrl, 1, Wx::wxALL | Wx::wxEXPAND, 3 );

	my $fgSizer2 = Wx::FlexGridSizer->new( 0, 2, 0, 0 );
	$fgSizer2->SetFlexibleDirection(Wx::wxBOTH);
	$fgSizer2->SetNonFlexibleGrowMode(Wx::wxFLEX_GROWMODE_SPECIFIED);
	$fgSizer2->Add( $m_staticText5, 0, Wx::wxALL, 5 );
	$fgSizer2->Add( $relations, 0, Wx::wxALL, 5 );

	my $buttons = Wx::BoxSizer->new(Wx::wxHORIZONTAL);
	$buttons->Add( $update, 0, Wx::wxALL, 5 );
	$buttons->Add( 0, 0, 1, Wx::wxEXPAND, 5 );
	$buttons->Add( $show, 0, Wx::wxALL, 5 );
	$buttons->Add( 0, 0, 1, Wx::wxEXPAND, 5 );
	$buttons->Add( $clean, 0, Wx::wxALL, 5 );
	$buttons->Add( 0, 0, 1, Wx::wxEXPAND, 5 );
	$buttons->Add( $width_ajust, 0, Wx::wxALL, 5 );
	$buttons->Add( 0, 0, 1, Wx::wxEXPAND, 5 );
	$buttons->Add( $close_button, 0, Wx::wxALL, 5 );

	my $vsizer = Wx::BoxSizer->new(Wx::wxVERTICAL);
	$vsizer->Add( $bSizer1, 0, Wx::wxEXPAND, 3 );
	$vsizer->Add( $m_staticline1_1, 0, Wx::wxEXPAND | Wx::wxALL, 1 );
	$vsizer->Add( $bSizer5, 1, Wx::wxALL | Wx::wxEXPAND, 1 );
	$vsizer->Add( $m_staticline1_2, 0, Wx::wxALL | Wx::wxEXPAND, 1 );
	$vsizer->Add( $fgSizer2, 0, Wx::wxALL | Wx::wxEXPAND, 3 );
	$vsizer->Add( $m_staticline1_3, 0, Wx::wxEXPAND | Wx::wxALL, 1 );
	$vsizer->Add( $buttons, 0, Wx::wxEXPAND, 3 );

	my $sizer = Wx::BoxSizer->new(Wx::wxHORIZONTAL);
	$sizer->Add( $vsizer, 1, Wx::wxALL, 1 );

	$self->SetSizer($sizer);
	$self->Layout;
	$sizer->Fit($self);
	$sizer->SetSizeHints($self);

	$self->{package_name} = $package_name->GetId;
	$self->{relation_title} = $relation_title->GetId;
	$self->{display_cardinality} = $display_cardinality->GetId;
	$self->{list_ctrl} = $list_ctrl->GetId;
	$self->{relations} = $relations->GetId;
	$self->{show} = $show->GetId;
	$self->{clean} = $clean->GetId;
	$self->{width_ajust} = $width_ajust->GetId;

	return $self;
}

sub package_name {
	Wx::Window::FindWindowById($_[0]->{package_name});
}

sub relation_title {
	Wx::Window::FindWindowById($_[0]->{relation_title});
}

sub display_cardinality {
	Wx::Window::FindWindowById($_[0]->{display_cardinality});
}

sub list_ctrl {
	Wx::Window::FindWindowById($_[0]->{list_ctrl});
}

sub relations {
	Wx::Window::FindWindowById($_[0]->{relations});
}

sub show {
	Wx::Window::FindWindowById($_[0]->{show});
}

sub clean {
	Wx::Window::FindWindowById($_[0]->{clean});
}

sub width_ajust {
	Wx::Window::FindWindowById($_[0]->{width_ajust});
}

sub about_clicked {
	$_[0]->main->error('Handler method about_clicked for event about.OnButtonClick not implemented');
}

sub _on_list_col_clicked {
	$_[0]->main->error('Handler method _on_list_col_clicked for event list_ctrl.OnListColClick not implemented');
}

sub _on_list_item_activated {
	$_[0]->main->error('Handler method _on_list_item_activated for event list_ctrl.OnListItemActivated not implemented');
}

sub update_clicked {
	$_[0]->main->error('Handler method update_clicked for event update.OnButtonClick not implemented');
}

sub show_clicked {
	$_[0]->main->error('Handler method show_clicked for event show.OnButtonClick not implemented');
}

sub clean_clicked {
	$_[0]->main->error('Handler method clean_clicked for event clean.OnButtonClick not implemented');
}

sub width_ajust_clicked {
	$_[0]->main->error('Handler method width_ajust_clicked for event width_ajust.OnButtonClick not implemented');
}

1;

# Copyright 2008-2011 The Padre development team as listed in Padre.pm.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.

