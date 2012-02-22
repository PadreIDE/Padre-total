package Padre::Plugin::Moose::FBP::Main;

## no critic

# This module was generated by Padre::Plugin::FormBuilder::Perl.
# To change this module edit the original .fbp file and regenerate.
# DO NOT MODIFY THIS FILE BY HAND!

use 5.008005;
use utf8;
use strict;
use warnings;
use Padre::Wx 'Grid';
use Padre::Wx::Role::Main ();
use Padre::Wx::Editor ();

our $VERSION = '0.05';
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
		Wx::gettext("Moose!"),
		Wx::DefaultPosition,
		[ 758, 575 ],
		Wx::DEFAULT_DIALOG_STYLE,
	);

	$self->{tree_label} = Wx::StaticText->new(
		$self,
		-1,
		Wx::gettext("Outline:"),
	);

	$self->{tree} = Wx::TreeCtrl->new(
		$self,
		-1,
		Wx::DefaultPosition,
		Wx::DefaultSize,
		Wx::TR_DEFAULT_STYLE,
	);

	Wx::Event::EVT_TREE_SEL_CHANGED(
		$self,
		$self->{tree},
		sub {
			shift->on_tree_selection_change(@_);
		},
	);

	$self->{add_class_button} = Wx::Button->new(
		$self,
		-1,
		Wx::gettext("Class"),
		Wx::DefaultPosition,
		Wx::DefaultSize,
	);

	Wx::Event::EVT_BUTTON(
		$self,
		$self->{add_class_button},
		sub {
			shift->on_add_class_button(@_);
		},
	);

	$self->{add_role_button} = Wx::Button->new(
		$self,
		-1,
		Wx::gettext("Role"),
		Wx::DefaultPosition,
		Wx::DefaultSize,
	);

	Wx::Event::EVT_BUTTON(
		$self,
		$self->{add_role_button},
		sub {
			shift->on_add_role_button(@_);
		},
	);

	$self->{add_attribute_button} = Wx::Button->new(
		$self,
		-1,
		Wx::gettext("Attribute"),
		Wx::DefaultPosition,
		Wx::DefaultSize,
	);

	Wx::Event::EVT_BUTTON(
		$self,
		$self->{add_attribute_button},
		sub {
			shift->on_add_attribute_button(@_);
		},
	);

	$self->{add_subtype_button} = Wx::Button->new(
		$self,
		-1,
		Wx::gettext("Subtype"),
		Wx::DefaultPosition,
		Wx::DefaultSize,
	);

	Wx::Event::EVT_BUTTON(
		$self,
		$self->{add_subtype_button},
		sub {
			shift->on_add_subtype_button(@_);
		},
	);

	$self->{add_method_button} = Wx::Button->new(
		$self,
		-1,
		Wx::gettext("Method"),
		Wx::DefaultPosition,
		Wx::DefaultSize,
	);

	Wx::Event::EVT_BUTTON(
		$self,
		$self->{add_method_button},
		sub {
			shift->on_add_method_button(@_);
		},
	);

	$self->{grid_label} = Wx::StaticText->new(
		$self,
		-1,
		Wx::gettext("Inspector:"),
	);

	$self->{grid} = Wx::Grid->new(
		$self,
		-1,
		Wx::DefaultPosition,
		Wx::DefaultSize,
	);
	$self->{grid}->CreateGrid( 5, 2 );
	$self->{grid}->EnableEditing(1);
	$self->{grid}->EnableGridLines(1);
	$self->{grid}->EnableDragGridSize(0);
	$self->{grid}->SetMargins( 0, 0 );
	$self->{grid}->SetColSize( 0, 150 );
	$self->{grid}->SetColSize( 1, 75 );
	$self->{grid}->EnableDragColMove(0);
	$self->{grid}->EnableDragColSize(1);
	$self->{grid}->SetColLabelSize(0);
	$self->{grid}->SetColLabelAlignment( Wx::ALIGN_CENTRE, Wx::ALIGN_CENTRE );
	$self->{grid}->EnableDragRowSize(1);
	$self->{grid}->SetRowLabelAlignment( Wx::ALIGN_CENTRE, Wx::ALIGN_CENTRE );
	$self->{grid}->SetDefaultCellAlignment( Wx::ALIGN_LEFT, Wx::ALIGN_TOP );

	Wx::Event::EVT_GRID_CELL_CHANGE(
		$self->{grid},
		sub {
			$self->on_grid_cell_change($_[1]);
		},
	);

	$self->{comments_checkbox} = Wx::CheckBox->new(
		$self,
		-1,
		Wx::gettext("Comments?"),
		Wx::DefaultPosition,
		Wx::DefaultSize,
	);

	Wx::Event::EVT_CHECKBOX(
		$self,
		$self->{comments_checkbox},
		sub {
			shift->on_comments_checkbox(@_);
		},
	);

	$self->{sample_code_checkbox} = Wx::CheckBox->new(
		$self,
		-1,
		Wx::gettext("Sample code?"),
		Wx::DefaultPosition,
		Wx::DefaultSize,
	);

	Wx::Event::EVT_CHECKBOX(
		$self,
		$self->{sample_code_checkbox},
		sub {
			shift->on_sample_code_checkbox(@_);
		},
	);

	$self->{preview} = Padre::Wx::Editor->new(
		$self,
		-1,
	);

	$self->{moose_manual_hyperlink} = Wx::HyperlinkCtrl->new(
		$self,
		-1,
		Wx::gettext("Moose Manual"),
		"https://metacpan.org/module/Moose::Manual",
		Wx::DefaultPosition,
		Wx::DefaultSize,
		Wx::HL_DEFAULT_STYLE,
	);

	$self->{moose_cookbook_hyperlink} = Wx::HyperlinkCtrl->new(
		$self,
		-1,
		Wx::gettext("How to Cook a Moose?"),
		"https://metacpan.org/module/Moose::Cookbook",
		Wx::DefaultPosition,
		Wx::DefaultSize,
		Wx::HL_DEFAULT_STYLE,
	);

	$self->{moose_website_hyperlink} = Wx::HyperlinkCtrl->new(
		$self,
		-1,
		Wx::gettext("Moose Website"),
		"http://moose.iinteractive.com/",
		Wx::DefaultPosition,
		Wx::DefaultSize,
		Wx::HL_DEFAULT_STYLE,
	);

	$self->{insert_code_button} = Wx::Button->new(
		$self,
		-1,
		Wx::gettext("Insert code"),
		Wx::DefaultPosition,
		Wx::DefaultSize,
	);

	Wx::Event::EVT_BUTTON(
		$self,
		$self->{insert_code_button},
		sub {
			shift->on_insert_button_clicked(@_);
		},
	);

	$self->{about_button} = Wx::Button->new(
		$self,
		-1,
		Wx::gettext("About"),
		Wx::DefaultPosition,
		Wx::DefaultSize,
	);

	Wx::Event::EVT_BUTTON(
		$self,
		$self->{about_button},
		sub {
			shift->on_about_button_clicked(@_);
		},
	);

	$self->{close_button} = Wx::Button->new(
		$self,
		Wx::ID_CANCEL,
		Wx::gettext("Close"),
		Wx::DefaultPosition,
		Wx::DefaultSize,
	);

	my $tree_sizer = Wx::BoxSizer->new(Wx::VERTICAL);
	$tree_sizer->Add( $self->{tree_label}, 0, Wx::ALL, 5 );
	$tree_sizer->Add( $self->{tree}, 1, Wx::ALL | Wx::EXPAND, 5 );

	my $action_bar_sizer = Wx::BoxSizer->new(Wx::HORIZONTAL);
	$action_bar_sizer->Add( $self->{add_class_button}, 0, Wx::ALIGN_CENTER_HORIZONTAL | Wx::ALL, 2 );
	$action_bar_sizer->Add( $self->{add_role_button}, 0, Wx::ALL, 2 );
	$action_bar_sizer->Add( $self->{add_attribute_button}, 0, Wx::ALL, 2 );
	$action_bar_sizer->Add( $self->{add_subtype_button}, 0, Wx::ALL, 2 );
	$action_bar_sizer->Add( $self->{add_method_button}, 0, Wx::ALL, 2 );

	my $left_sizer = Wx::BoxSizer->new(Wx::VERTICAL);
	$left_sizer->Add( $tree_sizer, 1, Wx::EXPAND, 5 );
	$left_sizer->Add( $action_bar_sizer, 0, Wx::ALL, 2 );

	my $bottom_sizer = Wx::BoxSizer->new(Wx::HORIZONTAL);
	$bottom_sizer->Add( $self->{comments_checkbox}, 0, Wx::ALL, 5 );
	$bottom_sizer->Add( $self->{sample_code_checkbox}, 0, Wx::ALL, 5 );

	my $right_sizer = Wx::BoxSizer->new(Wx::VERTICAL);
	$right_sizer->Add( $self->{grid_label}, 0, Wx::ALL, 5 );
	$right_sizer->Add( $self->{grid}, 0, Wx::ALL, 5 );
	$right_sizer->Add( $bottom_sizer, 0, Wx::EXPAND, 5 );

	my $top_sizer = Wx::BoxSizer->new(Wx::HORIZONTAL);
	$top_sizer->Add( $left_sizer, 2, Wx::EXPAND, 5 );
	$top_sizer->Add( $right_sizer, 1, Wx::EXPAND, 5 );

	my $hyperlink_sizer = Wx::BoxSizer->new(Wx::HORIZONTAL);
	$hyperlink_sizer->Add( $self->{moose_manual_hyperlink}, 0, Wx::ALIGN_CENTER_VERTICAL | Wx::ALL, 5 );
	$hyperlink_sizer->Add( $self->{moose_cookbook_hyperlink}, 0, Wx::ALIGN_CENTER_VERTICAL | Wx::ALL, 5 );
	$hyperlink_sizer->Add( $self->{moose_website_hyperlink}, 0, Wx::ALIGN_CENTER_VERTICAL | Wx::ALL, 5 );

	my $buttons_sizer = Wx::BoxSizer->new(Wx::HORIZONTAL);
	$buttons_sizer->Add( $hyperlink_sizer, 0, Wx::EXPAND, 5 );
	$buttons_sizer->Add( 10, 0, 1, Wx::EXPAND, 5 );
	$buttons_sizer->Add( $self->{insert_code_button}, 0, Wx::ALL, 2 );
	$buttons_sizer->Add( 30, 0, 0, Wx::EXPAND, 5 );
	$buttons_sizer->Add( $self->{about_button}, 0, Wx::ALL, 2 );
	$buttons_sizer->Add( $self->{close_button}, 0, Wx::ALL, 2 );

	my $main_sizer = Wx::BoxSizer->new(Wx::VERTICAL);
	$main_sizer->Add( $top_sizer, 1, Wx::EXPAND, 5 );
	$main_sizer->Add( $self->{preview}, 1, Wx::ALL | Wx::EXPAND, 5 );
	$main_sizer->Add( $buttons_sizer, 0, Wx::EXPAND, 5 );

	$self->SetSizer($main_sizer);
	$self->Layout;

	return $self;
}

sub on_tree_selection_change {
	$_[0]->main->error('Handler method on_tree_selection_change for event tree.OnTreeSelChanged not implemented');
}

sub on_add_class_button {
	$_[0]->main->error('Handler method on_add_class_button for event add_class_button.OnButtonClick not implemented');
}

sub on_add_role_button {
	$_[0]->main->error('Handler method on_add_role_button for event add_role_button.OnButtonClick not implemented');
}

sub on_add_attribute_button {
	$_[0]->main->error('Handler method on_add_attribute_button for event add_attribute_button.OnButtonClick not implemented');
}

sub on_add_subtype_button {
	$_[0]->main->error('Handler method on_add_subtype_button for event add_subtype_button.OnButtonClick not implemented');
}

sub on_add_method_button {
	$_[0]->main->error('Handler method on_add_method_button for event add_method_button.OnButtonClick not implemented');
}

sub on_grid_cell_change {
	$_[0]->main->error('Handler method on_grid_cell_change for event grid.OnGridCellChange not implemented');
}

sub on_comments_checkbox {
	$_[0]->main->error('Handler method on_comments_checkbox for event comments_checkbox.OnCheckBox not implemented');
}

sub on_sample_code_checkbox {
	$_[0]->main->error('Handler method on_sample_code_checkbox for event sample_code_checkbox.OnCheckBox not implemented');
}

sub on_insert_button_clicked {
	$_[0]->main->error('Handler method on_insert_button_clicked for event insert_code_button.OnButtonClick not implemented');
}

sub on_about_button_clicked {
	$_[0]->main->error('Handler method on_about_button_clicked for event about_button.OnButtonClick not implemented');
}

1;

# Copyright 2008-2012 The Padre development team as listed in Padre.pm.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.

