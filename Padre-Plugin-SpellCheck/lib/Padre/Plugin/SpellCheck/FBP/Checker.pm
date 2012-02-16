package Padre::Plugin::SpellCheck::FBP::Checker;

## no critic

# This module was generated by Padre::Plugin::FormBuilder::Perl.
# To change this module edit the original .fbp file and regenerate.
# DO NOT MODIFY THIS FILE BY HAND!

use 5.008005;
use utf8;
use strict;
use warnings;
use Padre::Wx ();
use Padre::Wx::Role::Main ();

our $VERSION = '1.22';
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
		Wx::gettext("Padre-Plugin-SpellCheck"),
		Wx::DefaultPosition,
		Wx::DefaultSize,
		Wx::DEFAULT_DIALOG_STYLE,
	);

	$self->{labeltext} = Wx::StaticText->new(
		$self,
		-1,
		Wx::gettext("Spell check finished:"),
	);
	$self->{labeltext}->SetMinSize( [ 124, -1 ] );

	$self->{label} = Wx::StaticText->new(
		$self,
		-1,
		Wx::gettext("Click Close"),
	);

	$self->{list} = Wx::ListCtrl->new(
		$self,
		-1,
		Wx::DefaultPosition,
		Wx::DefaultSize,
		Wx::LC_LIST,
	);

	Wx::Event::EVT_LIST_ITEM_ACTIVATED(
		$self,
		$self->{list},
		sub {
			shift->_on_butreplace_clicked(@_);
		},
	);

	$self->{m_button1} = Wx::Button->new(
		$self,
		-1,
		Wx::gettext("&Add to dictionary"),
		Wx::DefaultPosition,
		Wx::DefaultSize,
	);
	$self->{m_button1}->Disable;

	$self->{replace} = Wx::Button->new(
		$self,
		-1,
		Wx::gettext("&Replace"),
		Wx::DefaultPosition,
		Wx::DefaultSize,
	);
	$self->{replace}->SetToolTip(
		Wx::gettext("Replace the highlighted word in Padre Editor.\nwith your selected word")
	);

	Wx::Event::EVT_BUTTON(
		$self,
		$self->{replace},
		sub {
			shift->_on_replace_clicked(@_);
		},
	);

	$self->{replaece_all} = Wx::Button->new(
		$self,
		-1,
		Wx::gettext("R&eplace all"),
		Wx::DefaultPosition,
		Wx::DefaultSize,
	);
	$self->{replaece_all}->SetToolTip(
		Wx::gettext("Same as Replace\nbut also every future occurance\nin current Check")
	);

	Wx::Event::EVT_BUTTON(
		$self,
		$self->{replaece_all},
		sub {
			shift->_on_replace_all_clicked(@_);
		},
	);

	$self->{ignore} = Wx::Button->new(
		$self,
		-1,
		Wx::gettext("&Ignore"),
		Wx::DefaultPosition,
		Wx::DefaultSize,
	);
	$self->{ignore}->SetToolTip(
		Wx::gettext("Ignore the highlighted word in Padre Editor.")
	);

	Wx::Event::EVT_BUTTON(
		$self,
		$self->{ignore},
		sub {
			shift->_on_ignore_clicked(@_);
		},
	);

	$self->{ignore_all} = Wx::Button->new(
		$self,
		-1,
		Wx::gettext("I&gnore all"),
		Wx::DefaultPosition,
		Wx::DefaultSize,
	);
	$self->{ignore_all}->SetToolTip(
		Wx::gettext("Same as Ignore\nbut also every future occurance\nin current Check")
	);

	Wx::Event::EVT_BUTTON(
		$self,
		$self->{ignore_all},
		sub {
			shift->_on_ignore_all_clicked(@_);
		},
	);

	$self->{m_button6} = Wx::Button->new(
		$self,
		Wx::ID_CANCEL,
		Wx::gettext("&Close"),
		Wx::DefaultPosition,
		Wx::DefaultSize,
	);
	$self->{m_button6}->SetDefault;

	$self->{status_info} = Wx::StaticBoxSizer->new(
		Wx::StaticBox->new(
			$self,
			-1,
			Wx::gettext("Status Info."),
		),
		Wx::HORIZONTAL,
	);
	$self->{status_info}->Add( $self->{labeltext}, 0, Wx::ALL | Wx::EXPAND, 5 );
	$self->{status_info}->Add( $self->{label}, 0, Wx::ALL | Wx::EXPAND, 5 );

	my $bSizer21 = Wx::BoxSizer->new(Wx::VERTICAL);
	$bSizer21->Add( $self->{status_info}, 1, Wx::ALL | Wx::EXPAND, 5 );

	my $sbSizer2 = Wx::StaticBoxSizer->new(
		Wx::StaticBox->new(
			$self,
			-1,
			Wx::gettext("Suggestions"),
		),
		Wx::VERTICAL,
	);
	$sbSizer2->Add( $self->{list}, 1, Wx::ALL | Wx::EXPAND, 5 );

	my $bSizer22 = Wx::BoxSizer->new(Wx::VERTICAL);
	$bSizer22->Add( $sbSizer2, 1, Wx::ALL | Wx::EXPAND, 5 );

	my $bSizer2 = Wx::BoxSizer->new(Wx::VERTICAL);
	$bSizer2->Add( $bSizer21, 0, Wx::ALL | Wx::EXPAND, 5 );
	$bSizer2->Add( $bSizer22, 1, Wx::ALL | Wx::EXPAND, 5 );

	my $bSizer3 = Wx::BoxSizer->new(Wx::VERTICAL);
	$bSizer3->Add( $self->{m_button1}, 0, Wx::ALL | Wx::EXPAND, 5 );
	$bSizer3->Add( $self->{replace}, 0, Wx::ALL | Wx::EXPAND, 5 );
	$bSizer3->Add( $self->{replaece_all}, 0, Wx::ALL | Wx::EXPAND, 5 );
	$bSizer3->Add( $self->{ignore}, 0, Wx::ALL | Wx::EXPAND, 5 );
	$bSizer3->Add( $self->{ignore_all}, 0, Wx::ALL | Wx::EXPAND, 5 );
	$bSizer3->Add( $self->{m_button6}, 0, Wx::ALL | Wx::EXPAND, 5 );

	my $bSizer1 = Wx::BoxSizer->new(Wx::HORIZONTAL);
	$bSizer1->Add( $bSizer2, 1, Wx::ALL | Wx::EXPAND, 5 );
	$bSizer1->Add( $bSizer3, 0, Wx::ALL | Wx::EXPAND, 5 );

	$self->SetSizerAndFit($bSizer1);
	$self->Layout;

	return $self;
}

sub labeltext {
	$_[0]->{labeltext};
}

sub label {
	$_[0]->{label};
}

sub list {
	$_[0]->{list};
}

sub replace {
	$_[0]->{replace};
}

sub replaece_all {
	$_[0]->{replaece_all};
}

sub ignore {
	$_[0]->{ignore};
}

sub ignore_all {
	$_[0]->{ignore_all};
}

sub _on_butreplace_clicked {
	$_[0]->main->error('Handler method _on_butreplace_clicked for event list.OnListItemActivated not implemented');
}

sub _on_replace_clicked {
	$_[0]->main->error('Handler method _on_replace_clicked for event replace.OnButtonClick not implemented');
}

sub _on_replace_all_clicked {
	$_[0]->main->error('Handler method _on_replace_all_clicked for event replaece_all.OnButtonClick not implemented');
}

sub _on_ignore_clicked {
	$_[0]->main->error('Handler method _on_ignore_clicked for event ignore.OnButtonClick not implemented');
}

sub _on_ignore_all_clicked {
	$_[0]->main->error('Handler method _on_ignore_all_clicked for event ignore_all.OnButtonClick not implemented');
}

1;

# Copyright 2008-2012 The Padre development team as listed in Padre.pm.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.

