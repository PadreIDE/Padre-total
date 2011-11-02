package Padre::Wx::FBP::CPAN;

## no critic

# This module was generated by Padre::Plugin::FormBuilder::Perl.
# To change this module edit the original .fbp file and regenerate.
# DO NOT MODIFY THIS FILE BY HAND!

use 5.008;
use strict;
use warnings;
use Padre::Wx ();
use Padre::Wx::Role::Main ();
use Padre::Wx::HtmlWindow ();

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
		[ 235, 530 ],
		Wx::TAB_TRAVERSAL,
	);

	$self->{m_notebook} = Wx::Notebook->new(
		$self,
		-1,
		Wx::DefaultPosition,
		Wx::DefaultSize,
	);

	$self->{search_panel} = Wx::Panel->new(
		$self->{m_notebook},
		-1,
		Wx::DefaultPosition,
		Wx::DefaultSize,
		Wx::TAB_TRAVERSAL,
	);

	$self->{search} = Wx::TextCtrl->new(
		$self->{search_panel},
		-1,
		"",
		Wx::DefaultPosition,
		Wx::DefaultSize,
	);

	Wx::Event::EVT_TEXT(
		$self,
		$self->{search},
		sub {
			shift->on_search_text(@_);
		},
	);

	$self->{list} = Wx::ListCtrl->new(
		$self->{search_panel},
		-1,
		Wx::DefaultPosition,
		Wx::DefaultSize,
		Wx::LC_REPORT | Wx::LC_SINGLE_SEL,
	);

	Wx::Event::EVT_LIST_COL_CLICK(
		$self,
		$self->{list},
		sub {
			shift->on_list_column_click(@_);
		},
	);

	Wx::Event::EVT_LIST_ITEM_SELECTED(
		$self,
		$self->{list},
		sub {
			shift->on_list_item_selected(@_);
		},
	);

	$self->{recent_panel} = Wx::Panel->new(
		$self->{m_notebook},
		-1,
		Wx::DefaultPosition,
		Wx::DefaultSize,
		Wx::TAB_TRAVERSAL,
	);

	$self->{recent_list} = Wx::ListCtrl->new(
		$self->{recent_panel},
		-1,
		Wx::DefaultPosition,
		Wx::DefaultSize,
		Wx::LC_REPORT | Wx::LC_SINGLE_SEL,
	);

	Wx::Event::EVT_LIST_COL_CLICK(
		$self,
		$self->{recent_list},
		sub {
			shift->on_recent_list_column_click(@_);
		},
	);

	Wx::Event::EVT_LIST_ITEM_SELECTED(
		$self,
		$self->{recent_list},
		sub {
			shift->on_list_item_selected(@_);
		},
	);

	$self->{refresh_recent} = Wx::Button->new(
		$self->{recent_panel},
		-1,
		Wx::gettext("Refresh"),
		Wx::DefaultPosition,
		Wx::DefaultSize,
	);

	Wx::Event::EVT_BUTTON(
		$self,
		$self->{refresh_recent},
		sub {
			shift->on_refresh_recent_click(@_);
		},
	);

	$self->{favorite_panel} = Wx::Panel->new(
		$self->{m_notebook},
		-1,
		Wx::DefaultPosition,
		Wx::DefaultSize,
		Wx::TAB_TRAVERSAL,
	);

	$self->{favorite_list} = Wx::ListCtrl->new(
		$self->{favorite_panel},
		-1,
		Wx::DefaultPosition,
		Wx::DefaultSize,
		Wx::LC_REPORT | Wx::LC_SINGLE_SEL,
	);

	Wx::Event::EVT_LIST_COL_CLICK(
		$self,
		$self->{favorite_list},
		sub {
			shift->on_favorite_list_column_click(@_);
		},
	);

	Wx::Event::EVT_LIST_ITEM_SELECTED(
		$self,
		$self->{favorite_list},
		sub {
			shift->on_list_item_selected(@_);
		},
	);

	$self->{refresh_favorite} = Wx::Button->new(
		$self->{favorite_panel},
		-1,
		Wx::gettext("Refresh"),
		Wx::DefaultPosition,
		Wx::DefaultSize,
	);

	Wx::Event::EVT_BUTTON(
		$self,
		$self->{refresh_favorite},
		sub {
			shift->on_refresh_favorite_click(@_);
		},
	);

	$self->{doc} = Padre::Wx::HtmlWindow->new(
		$self,
		-1,
		Wx::DefaultPosition,
		Wx::DefaultSize,
		Wx::STATIC_BORDER,
	);
	$self->{doc}->SetBackgroundColour(
		Wx::Colour->new( 253, 252, 187 )
	);

	$self->{synopsis} = Wx::Button->new(
		$self,
		-1,
		Wx::gettext("Insert Synopsis"),
		Wx::DefaultPosition,
		Wx::DefaultSize,
	);

	Wx::Event::EVT_BUTTON(
		$self,
		$self->{synopsis},
		sub {
			shift->on_synopsis_click(@_);
		},
	);

	$self->{install} = Wx::Button->new(
		$self,
		-1,
		Wx::gettext("Install"),
		Wx::DefaultPosition,
		Wx::DefaultSize,
	);

	Wx::Event::EVT_BUTTON(
		$self,
		$self->{install},
		sub {
			shift->on_install_click(@_);
		},
	);

	my $search_sizer = Wx::BoxSizer->new(Wx::HORIZONTAL);
	$search_sizer->Add( $self->{search}, 1, Wx::ALIGN_CENTER_VERTICAL, 0 );

	my $search_panel_sizer = Wx::BoxSizer->new(Wx::VERTICAL);
	$search_panel_sizer->Add( $search_sizer, 0, Wx::ALL | Wx::EXPAND, 1 );
	$search_panel_sizer->Add( $self->{list}, 1, Wx::ALL | Wx::EXPAND, 1 );

	$self->{search_panel}->SetSizerAndFit($search_panel_sizer);
	$self->{search_panel}->Layout;

	my $recent_panel_sizer = Wx::BoxSizer->new(Wx::VERTICAL);
	$recent_panel_sizer->Add( $self->{recent_list}, 1, Wx::ALL | Wx::EXPAND, 5 );
	$recent_panel_sizer->Add( $self->{refresh_recent}, 0, Wx::ALIGN_CENTER | Wx::ALL, 1 );

	$self->{recent_panel}->SetSizerAndFit($recent_panel_sizer);
	$self->{recent_panel}->Layout;

	my $favorite_panel_sizer = Wx::BoxSizer->new(Wx::VERTICAL);
	$favorite_panel_sizer->Add( $self->{favorite_list}, 1, Wx::ALL | Wx::EXPAND, 5 );
	$favorite_panel_sizer->Add( $self->{refresh_favorite}, 0, Wx::ALIGN_CENTER | Wx::ALL, 1 );

	$self->{favorite_panel}->SetSizerAndFit($favorite_panel_sizer);
	$self->{favorite_panel}->Layout;

	$self->{m_notebook}->AddPage( $self->{search_panel}, Wx::gettext("Search"), 1 );
	$self->{m_notebook}->AddPage( $self->{recent_panel}, Wx::gettext("Recent"), 0 );
	$self->{m_notebook}->AddPage( $self->{favorite_panel}, Wx::gettext("Favorite"), 0 );

	my $button_sizer = Wx::FlexGridSizer->new( 2, 2, 0, 0 );
	$button_sizer->SetFlexibleDirection(Wx::BOTH);
	$button_sizer->SetNonFlexibleGrowMode(Wx::FLEX_GROWMODE_SPECIFIED);
	$button_sizer->Add( $self->{synopsis}, 0, Wx::ALL | Wx::EXPAND, 2 );
	$button_sizer->Add( $self->{install}, 0, Wx::ALIGN_CENTER, 2 );

	my $main_sizer = Wx::BoxSizer->new(Wx::VERTICAL);
	$main_sizer->Add( $self->{m_notebook}, 1, Wx::EXPAND | Wx::ALL, 5 );
	$main_sizer->Add( $self->{doc}, 1, Wx::ALL | Wx::EXPAND, 1 );
	$main_sizer->Add( $button_sizer, 0, Wx::EXPAND, 5 );

	$self->SetSizer($main_sizer);
	$self->Layout;

	return $self;
}

sub on_search_text {
	$_[0]->main->error('Handler method on_search_text for event search.OnText not implemented');
}

sub on_list_column_click {
	$_[0]->main->error('Handler method on_list_column_click for event list.OnListColClick not implemented');
}

sub on_list_item_selected {
	$_[0]->main->error('Handler method on_list_item_selected for event list.OnListItemSelected not implemented');
}

sub on_recent_list_column_click {
	$_[0]->main->error('Handler method on_recent_list_column_click for event recent_list.OnListColClick not implemented');
}

sub on_refresh_recent_click {
	$_[0]->main->error('Handler method on_refresh_recent_click for event refresh_recent.OnButtonClick not implemented');
}

sub on_favorite_list_column_click {
	$_[0]->main->error('Handler method on_favorite_list_column_click for event favorite_list.OnListColClick not implemented');
}

sub on_refresh_favorite_click {
	$_[0]->main->error('Handler method on_refresh_favorite_click for event refresh_favorite.OnButtonClick not implemented');
}

sub on_synopsis_click {
	$_[0]->main->error('Handler method on_synopsis_click for event synopsis.OnButtonClick not implemented');
}

sub on_install_click {
	$_[0]->main->error('Handler method on_install_click for event install.OnButtonClick not implemented');
}

1;

# Copyright 2008-2011 The Padre development team as listed in Padre.pm.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.

