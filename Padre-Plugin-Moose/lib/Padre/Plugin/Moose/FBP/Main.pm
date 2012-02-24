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

our $VERSION = '0.10';
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
		[ 759, 531 ],
		Wx::DEFAULT_DIALOG_STYLE,
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

	$self->{inspector} = Wx::Grid->new(
		$self,
		-1,
		Wx::DefaultPosition,
		Wx::DefaultSize,
	);
	$self->{inspector}->CreateGrid( 5, 2 );
	$self->{inspector}->EnableEditing(1);
	$self->{inspector}->EnableGridLines(1);
	$self->{inspector}->EnableDragGridSize(0);
	$self->{inspector}->SetMargins( 0, 0 );
	$self->{inspector}->SetColSize( 0, 150 );
	$self->{inspector}->SetColSize( 1, 75 );
	$self->{inspector}->EnableDragColMove(0);
	$self->{inspector}->EnableDragColSize(1);
	$self->{inspector}->SetColLabelSize(0);
	$self->{inspector}->SetColLabelAlignment( Wx::ALIGN_CENTRE, Wx::ALIGN_CENTRE );
	$self->{inspector}->EnableDragRowSize(1);
	$self->{inspector}->SetRowLabelAlignment( Wx::ALIGN_CENTRE, Wx::ALIGN_CENTRE );
	$self->{inspector}->SetDefaultCellAlignment( Wx::ALIGN_LEFT, Wx::ALIGN_TOP );

	Wx::Event::EVT_GRID_CELL_CHANGE(
		$self->{inspector},
		sub {
			$self->on_grid_cell_change($_[1]);
		},
	);

	$self->{help} = Wx::TextCtrl->new(
		$self,
		-1,
		"",
		Wx::DefaultPosition,
		Wx::DefaultSize,
		Wx::TE_MULTILINE | Wx::TE_READONLY | Wx::DOUBLE_BORDER | Wx::NO_BORDER,
	);

	$self->{palette} = Wx::Notebook->new(
		$self,
		-1,
		Wx::DefaultPosition,
		Wx::DefaultSize,
	);

	$self->{containers} = Wx::Panel->new(
		$self->{palette},
		-1,
		Wx::DefaultPosition,
		Wx::DefaultSize,
		Wx::TAB_TRAVERSAL,
	);

	$self->{add_class_button} = Wx::Button->new(
		$self->{containers},
		-1,
		Wx::gettext("&Class"),
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
		$self->{containers},
		-1,
		Wx::gettext("&Role"),
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

	$self->{members} = Wx::Panel->new(
		$self->{palette},
		-1,
		Wx::DefaultPosition,
		Wx::DefaultSize,
		Wx::TAB_TRAVERSAL,
	);

	$self->{add_attribute_button} = Wx::Button->new(
		$self->{members},
		-1,
		Wx::gettext("&Attribute"),
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
		$self->{members},
		-1,
		Wx::gettext("&Subtype"),
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
		$self->{members},
		-1,
		Wx::gettext("&Method"),
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

	$self->{online_refs} = Wx::Panel->new(
		$self->{palette},
		-1,
		Wx::DefaultPosition,
		Wx::DefaultSize,
		Wx::TAB_TRAVERSAL,
	);

	$self->{moose_manual_hyperlink} = Wx::HyperlinkCtrl->new(
		$self->{online_refs},
		-1,
		Wx::gettext("Moose Manual"),
		"https://metacpan.org/module/Moose::Manual",
		Wx::DefaultPosition,
		Wx::DefaultSize,
		Wx::HL_DEFAULT_STYLE,
	);

	$self->{moose_cookbook_hyperlink} = Wx::HyperlinkCtrl->new(
		$self->{online_refs},
		-1,
		Wx::gettext("How to Cook a Moose?"),
		"https://metacpan.org/module/Moose::Cookbook",
		Wx::DefaultPosition,
		Wx::DefaultSize,
		Wx::HL_DEFAULT_STYLE,
	);

	$self->{moose_website_hyperlink} = Wx::HyperlinkCtrl->new(
		$self->{online_refs},
		-1,
		Wx::gettext("Moose Website"),
		"http://moose.iinteractive.com/",
		Wx::DefaultPosition,
		Wx::DefaultSize,
		Wx::HL_DEFAULT_STYLE,
	);

	$self->{preview} = Padre::Wx::Editor->new(
		$self,
		-1,
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

	$self->{close_button} = Wx::Button->new(
		$self,
		Wx::ID_CANCEL,
		Wx::gettext("Close"),
		Wx::DefaultPosition,
		Wx::DefaultSize,
	);

	$self->{reset_button} = Wx::Button->new(
		$self,
		-1,
		Wx::gettext("Reset"),
		Wx::DefaultPosition,
		Wx::DefaultSize,
	);

	Wx::Event::EVT_BUTTON(
		$self,
		$self->{reset_button},
		sub {
			shift->on_reset_button_clicked(@_);
		},
	);

	$self->{generate_code_button} = Wx::Button->new(
		$self,
		-1,
		Wx::gettext("&Generate"),
		Wx::DefaultPosition,
		Wx::DefaultSize,
	);

	Wx::Event::EVT_BUTTON(
		$self,
		$self->{generate_code_button},
		sub {
			shift->on_generate_code_button_clicked(@_);
		},
	);

	my $tree_sizer = Wx::StaticBoxSizer->new(
		Wx::StaticBox->new(
			$self,
			-1,
			Wx::gettext("Object Tree"),
		),
		Wx::VERTICAL,
	);
	$tree_sizer->Add( $self->{tree}, 1, Wx::ALL | Wx::EXPAND, 5 );

	my $inspector_size = Wx::StaticBoxSizer->new(
		Wx::StaticBox->new(
			$self,
			-1,
			Wx::gettext("Inspector:"),
		),
		Wx::VERTICAL,
	);
	$inspector_size->Add( $self->{inspector}, 0, Wx::ALL, 5 );
	$inspector_size->Add( $self->{help}, 1, Wx::ALL | Wx::EXPAND, 5 );

	my $left_sizer = Wx::BoxSizer->new(Wx::VERTICAL);
	$left_sizer->Add( $tree_sizer, 1, Wx::EXPAND, 5 );
	$left_sizer->Add( $inspector_size, 1, Wx::EXPAND, 5 );

	my $container_sizer = Wx::BoxSizer->new(Wx::HORIZONTAL);
	$container_sizer->Add( $self->{add_class_button}, 0, Wx::ALIGN_CENTER_HORIZONTAL | Wx::ALL, 2 );
	$container_sizer->Add( $self->{add_role_button}, 0, Wx::ALL, 2 );

	$self->{containers}->SetSizerAndFit($container_sizer);
	$self->{containers}->Layout;

	my $members_sizer = Wx::BoxSizer->new(Wx::HORIZONTAL);
	$members_sizer->Add( $self->{add_attribute_button}, 0, Wx::ALL, 2 );
	$members_sizer->Add( $self->{add_subtype_button}, 0, Wx::ALL, 2 );
	$members_sizer->Add( $self->{add_method_button}, 0, Wx::ALL, 2 );

	$self->{members}->SetSizerAndFit($members_sizer);
	$self->{members}->Layout;

	my $online_refs_sizer = Wx::BoxSizer->new(Wx::HORIZONTAL);
	$online_refs_sizer->Add( $self->{moose_manual_hyperlink}, 0, Wx::ALIGN_CENTER_VERTICAL | Wx::ALL, 5 );
	$online_refs_sizer->Add( $self->{moose_cookbook_hyperlink}, 0, Wx::ALIGN_CENTER_VERTICAL | Wx::ALL, 5 );
	$online_refs_sizer->Add( $self->{moose_website_hyperlink}, 0, Wx::ALIGN_CENTER_VERTICAL | Wx::ALL, 5 );

	$self->{online_refs}->SetSizerAndFit($online_refs_sizer);
	$self->{online_refs}->Layout;

	$self->{palette}->AddPage( $self->{containers}, Wx::gettext("Containers"), 1 );
	$self->{palette}->AddPage( $self->{members}, Wx::gettext("Members"), 0 );
	$self->{palette}->AddPage( $self->{online_refs}, Wx::gettext("Online References"), 0 );

	my $palette_sizer = Wx::StaticBoxSizer->new(
		Wx::StaticBox->new(
			$self,
			-1,
			Wx::gettext("Palette"),
		),
		Wx::VERTICAL,
	);
	$palette_sizer->Add( $self->{palette}, 0, Wx::EXPAND | Wx::ALL, 5 );

	my $preview_sizer = Wx::StaticBoxSizer->new(
		Wx::StaticBox->new(
			$self,
			-1,
			Wx::gettext("The Code!"),
		),
		Wx::VERTICAL,
	);
	$preview_sizer->Add( $self->{preview}, 1, Wx::ALL | Wx::EXPAND, 5 );

	my $button_sizer = Wx::BoxSizer->new(Wx::HORIZONTAL);
	$button_sizer->Add( $self->{comments_checkbox}, 0, Wx::ALL, 5 );
	$button_sizer->Add( $self->{sample_code_checkbox}, 0, Wx::ALL, 5 );
	$button_sizer->Add( 0, 0, 1, Wx::EXPAND, 5 );
	$button_sizer->Add( $self->{close_button}, 0, Wx::ALL, 2 );
	$button_sizer->Add( $self->{reset_button}, 0, Wx::ALL, 2 );
	$button_sizer->Add( $self->{generate_code_button}, 0, Wx::ALL, 2 );
	$button_sizer->Add( 5, 0, 0, Wx::EXPAND, 5 );

	my $right_sizer = Wx::BoxSizer->new(Wx::VERTICAL);
	$right_sizer->Add( $palette_sizer, 0, Wx::EXPAND, 0 );
	$right_sizer->Add( $preview_sizer, 1, Wx::EXPAND, 10 );
	$right_sizer->Add( $button_sizer, 0, Wx::EXPAND, 5 );

	my $top_sizer = Wx::BoxSizer->new(Wx::HORIZONTAL);
	$top_sizer->Add( $left_sizer, 1, Wx::EXPAND, 5 );
	$top_sizer->Add( $right_sizer, 2, Wx::EXPAND, 5 );

	my $main_sizer = Wx::BoxSizer->new(Wx::VERTICAL);
	$main_sizer->Add( $top_sizer, 1, Wx::EXPAND, 5 );

	$self->SetSizer($main_sizer);
	$self->Layout;

	return $self;
}

sub on_tree_selection_change {
	$_[0]->main->error('Handler method on_tree_selection_change for event tree.OnTreeSelChanged not implemented');
}

sub on_grid_cell_change {
	$_[0]->main->error('Handler method on_grid_cell_change for event inspector.OnGridCellChange not implemented');
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

sub on_comments_checkbox {
	$_[0]->main->error('Handler method on_comments_checkbox for event comments_checkbox.OnCheckBox not implemented');
}

sub on_sample_code_checkbox {
	$_[0]->main->error('Handler method on_sample_code_checkbox for event sample_code_checkbox.OnCheckBox not implemented');
}

sub on_reset_button_clicked {
	$_[0]->main->error('Handler method on_reset_button_clicked for event reset_button.OnButtonClick not implemented');
}

sub on_generate_code_button_clicked {
	$_[0]->main->error('Handler method on_generate_code_button_clicked for event generate_code_button.OnButtonClick not implemented');
}

1;

# Copyright 2008-2012 The Padre development team as listed in Padre.pm.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.

