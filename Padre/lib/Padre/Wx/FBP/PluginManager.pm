package Padre::Wx::FBP::PluginManager;

## no critic

# This module was generated by Padre::Plugin::FormBuilder::Perl.
# To change this module edit the original .fbp file and regenerate.
# DO NOT MODIFY THIS FILE BY HAND!

use 5.008005;
use utf8;
use strict;
use warnings;
use Padre::Wx::Role::Main ();
use Padre::Wx 'Html';

our $VERSION = '0.97';
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
		Wx::gettext("Plug-in Manager"),
		Wx::DefaultPosition,
		Wx::DefaultSize,
		Wx::DEFAULT_DIALOG_STYLE | Wx::RESIZE_BORDER,
	);
	$self->SetSizeHints( [ 750, 500 ], Wx::DefaultSize );
	$self->SetMinSize( [ 750, 500 ] );

	$self->{m_splitter2} = Wx::SplitterWindow->new(
		$self,
		-1,
		Wx::DefaultPosition,
		Wx::DefaultSize,
		Wx::SP_3D,
	);
	$self->{m_splitter2}->SetSashGravity(0.0);

	$self->{m_panel5} = Wx::Panel->new(
		$self->{m_splitter2},
		-1,
		Wx::DefaultPosition,
		Wx::DefaultSize,
		Wx::TAB_TRAVERSAL,
	);

	$self->{list} = Wx::ListCtrl->new(
		$self->{m_panel5},
		-1,
		Wx::DefaultPosition,
		Wx::DefaultSize,
		Wx::LC_REPORT | Wx::LC_SINGLE_SEL,
	);

	Wx::Event::EVT_LIST_ITEM_SELECTED(
		$self,
		$self->{list},
		sub {
			shift->_on_list_item_selected(@_);
		},
	);

	$self->{m_panel4} = Wx::Panel->new(
		$self->{m_splitter2},
		-1,
		Wx::DefaultPosition,
		Wx::DefaultSize,
		Wx::TAB_TRAVERSAL,
	);

	$self->{details} = Wx::Panel->new(
		$self->{m_panel4},
		-1,
		Wx::DefaultPosition,
		Wx::DefaultSize,
		Wx::TAB_TRAVERSAL,
	);

	$self->{plugin_name} = Wx::StaticText->new(
		$self->{details},
		-1,
		Wx::gettext("plugin name"),
	);
	$self->{plugin_name}->SetFont(
		Wx::Font->new( Wx::NORMAL_FONT->GetPointSize, 70, 90, 92, 0, "" )
	);

	$self->{plugin_version} = Wx::StaticText->new(
		$self->{details},
		-1,
		Wx::gettext("plugin version"),
	);

	$self->{plugin_status} = Wx::StaticText->new(
		$self->{details},
		-1,
		Wx::gettext("plugin status"),
	);
	$self->{plugin_status}->SetFont(
		Wx::Font->new( Wx::NORMAL_FONT->GetPointSize, 70, 90, 92, 0, "" )
	);

	$self->{whtml} = Wx::HtmlWindow->new(
		$self->{details},
		-1,
		Wx::DefaultPosition,
		Wx::DefaultSize,
	);

	$self->{action} = Wx::Button->new(
		$self->{details},
		-1,
		Wx::gettext("Enable"),
		Wx::DefaultPosition,
		Wx::DefaultSize,
	);

	Wx::Event::EVT_BUTTON(
		$self,
		$self->{action},
		sub {
			shift->action_clicked(@_);
		},
	);

	$self->{preferences} = Wx::Button->new(
		$self->{details},
		-1,
		Wx::gettext("Preferences"),
		Wx::DefaultPosition,
		Wx::DefaultSize,
	);

	Wx::Event::EVT_BUTTON(
		$self,
		$self->{preferences},
		sub {
			shift->preferences_clicked(@_);
		},
	);

	$self->{cancel} = Wx::Button->new(
		$self->{details},
		Wx::ID_CANCEL,
		Wx::gettext("Close"),
		Wx::DefaultPosition,
		Wx::DefaultSize,
	);
	$self->{cancel}->SetDefault;

	my $bSizer136 = Wx::BoxSizer->new(Wx::VERTICAL);

	my $bSizer109 = Wx::BoxSizer->new(Wx::VERTICAL);
	$bSizer109->SetMinSize( [ 240, -1 ] );
	$bSizer109->Add( $self->{list}, 1, Wx::ALL | Wx::EXPAND, 5 );
	$bSizer109->Add( $bSizer136, 0, Wx::EXPAND, 5 );

	$self->{m_panel5}->SetSizerAndFit($bSizer109);
	$self->{m_panel5}->Layout;

	$self->{labels} = Wx::BoxSizer->new(Wx::HORIZONTAL);
	$self->{labels}->Add( $self->{plugin_name}, 0, Wx::ALIGN_BOTTOM | Wx::ALL, 5 );
	$self->{labels}->Add( 5, 0, 0, Wx::EXPAND, 5 );
	$self->{labels}->Add( $self->{plugin_version}, 0, Wx::ALIGN_BOTTOM | Wx::BOTTOM | Wx::RIGHT, 6 );
	$self->{labels}->Add( 50, 0, 1, Wx::EXPAND, 5 );
	$self->{labels}->Add( $self->{plugin_status}, 0, Wx::ALIGN_BOTTOM | Wx::ALL, 5 );

	my $bSizer113 = Wx::BoxSizer->new(Wx::HORIZONTAL);
	$bSizer113->Add( $self->{action}, 0, Wx::ALL, 5 );
	$bSizer113->Add( $self->{preferences}, 0, Wx::BOTTOM | Wx::RIGHT | Wx::TOP, 5 );
	$bSizer113->Add( 50, 0, 1, Wx::EXPAND, 5 );
	$bSizer113->Add( $self->{cancel}, 0, Wx::ALL, 5 );

	my $bSizer110 = Wx::BoxSizer->new(Wx::VERTICAL);
	$bSizer110->Add( $self->{labels}, 0, Wx::EXPAND, 5 );
	$bSizer110->Add( $self->{whtml}, 1, Wx::EXPAND | Wx::LEFT | Wx::RIGHT, 5 );
	$bSizer110->Add( $bSizer113, 0, Wx::EXPAND, 5 );

	$self->{details}->SetSizerAndFit($bSizer110);
	$self->{details}->Layout;

	my $bSizer135 = Wx::BoxSizer->new(Wx::VERTICAL);
	$bSizer135->Add( $self->{details}, 1, Wx::EXPAND, 0 );

	$self->{m_panel4}->SetSizerAndFit($bSizer135);
	$self->{m_panel4}->Layout;

	$self->{m_splitter2}->SplitVertically(
		$self->{m_panel5},
		$self->{m_panel4},
		220,
	);

	my $bSizer108 = Wx::BoxSizer->new(Wx::HORIZONTAL);
	$bSizer108->Add( $self->{m_splitter2}, 1, Wx::EXPAND, 5 );

	$self->SetSizerAndFit($bSizer108);
	$self->Layout;

	return $self;
}

sub _on_list_item_selected {
	$_[0]->main->error('Handler method _on_list_item_selected for event list.OnListItemSelected not implemented');
}

sub action_clicked {
	$_[0]->main->error('Handler method action_clicked for event action.OnButtonClick not implemented');
}

sub preferences_clicked {
	$_[0]->main->error('Handler method preferences_clicked for event preferences.OnButtonClick not implemented');
}

1;

# Copyright 2008-2012 The Padre development team as listed in Padre.pm.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.

