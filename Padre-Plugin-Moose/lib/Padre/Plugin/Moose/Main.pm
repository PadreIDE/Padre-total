package Padre::Plugin::Moose::Main;

use 5.008;
use strict;
use warnings;
use Padre::Plugin::Moose::FBP::Main ();
use Padre::Plugin::Moose::Program ();
use Padre::Plugin::Moose::Class ();
use Padre::Plugin::Moose::Role ();
use Padre::Plugin::Moose::Attribute ();
use Padre::Plugin::Moose::Subtype ();

our $VERSION = '0.04';
our @ISA     = qw{
	Padre::Plugin::Moose::FBP::Main
};

sub new {
	my $class = shift;
	my $main  = shift;

	my $self = $class->SUPER::new($main);
	$self->CenterOnParent;

	$self->{class_count} = 1;
	$self->{role_count} = 1;
	$self->{attribute_count} = 1;
	$self->{subtype_count} = 1;
	
	$self->{program} = Padre::Plugin::Moose::Program->new;

	# Defaults
	$self->{comments_checkbox}->SetValue(1);
	$self->{sample_code_checkbox}->SetValue(1);
	
	# TODO Bug Alias to fix the wxFormBuilder bug regarding this one
	my $grid = $self->{grid};
	$grid->SetRowLabelSize(0);

	for my $row (0..$grid->GetNumberRows-1) {
		$grid->SetReadOnly($row, 0);
	}

	# Hide it!
	$grid->Show(0);

	# Setup preview editor
	my $preview = $self->{preview};
	$preview->{Document} = Padre::Document->new( mimetype => 'application/x-perl', );
	$preview->{Document}->set_editor($preview);
	$preview->Show(1);

	$preview->SetLexer('application/x-perl');
	$preview->SetText("\n# Generated Perl code is shown here");

	# Apply the current theme
	my $style = $main->config->editor_style;
	my $theme = Padre::Wx::Theme->find($style)->clone;
	$theme->apply($preview);

	$preview->SetReadOnly(1);

	return $self;
}

sub on_about_button_clicked {
	require Moose;
	require Padre::Unload;
	my $about = Wx::AboutDialogInfo->new;
	$about->SetName('Padre::Plugin::Moose');
	$about->SetDescription(
		Wx::gettext('Moose support for Padre') . "\n\n"
			. sprintf(
			Wx::gettext('This system is running Moose version %s'),
			$Moose::VERSION
			)
	);
	$about->SetVersion($Padre::Plugin::Moose::VERSION);
	Padre::Unload->unload('Moose');
	Wx::AboutBox($about);

	return;
}

sub on_add_class_button {
	my $self = shift;

	my $grid = $self->{grid};
	$grid->DeleteRows(0, $grid->GetNumberRows);
	$grid->InsertRows(0, 5);
	$grid->SetCellValue(0,0, Wx::gettext('Name:'));
	$grid->SetCellValue(1,0, Wx::gettext('Superclass:'));
	$grid->SetCellValue(2,0, Wx::gettext('Roles:'));
	$grid->SetCellValue(3,0, Wx::gettext('Clean namespace?'));
	$grid->SetCellValue(4,0, Wx::gettext('Make Immutable?'));

	for (3..4) {
		$grid->SetCellEditor($_, 1, Wx::GridCellBoolEditor->new);
		$grid->SetCellValue($_,1, 1) ;
	}
	$grid->SetGridCursor(0,1);
	$grid->Show(1);
	$self->Layout;
	$grid->SetFocus;
	$grid->SetGridCursor(0,1);

	my $class_name = "Class" . $self->{class_count};
	$grid->SetCellValue(0,1, $class_name);
	$self->{class_count}++;

	# Add a new class object to program
	my $class = Padre::Plugin::Moose::Class->new;
	$class->name($class_name);
	$class->immutable(1);
	$class->namespace_autoclean(1);
	push @{$self->{program}->classes}, $class;

	$self->show_code_in_preview();
}

sub show_code_in_preview {
	my $self = shift;

	eval {
		# Generate code
		my $code = $self->{program}->to_code(
			$self->{comments_checkbox}->IsChecked, 
			$self->{sample_code_checkbox}->IsChecked);

		# And show it in preview editor
		my $preview = $self->{preview};
		$preview->SetReadOnly(0);
		$preview->SetText($code);
		$preview->SetReadOnly(1);

		# Update tree
		$self->update_tree;
	};
	if($@) {
		$self->main->error(Wx::gettext("Error: " . $@));
	}
}

sub on_add_role_button {
	my $self = shift;
	
	my $grid = $self->{grid};
	$grid->DeleteRows(0, $grid->GetNumberRows);
	$grid->InsertRows(0, 2);
	$grid->SetCellValue(0,0, Wx::gettext('Name:'));
	$grid->SetCellValue(1,0, Wx::gettext('Requires:'));
	$grid->SetGridCursor(0,1);
	$grid->Show(1);
	$self->Layout;
	$grid->SetFocus;
	$grid->SetGridCursor(0,1);

	my $role_name = "Role" . $self->{role_count};
	$grid->SetCellValue(0,1, $role_name);
	$self->{role_count}++;
	
	# Add a new role object to program
	my $role = Padre::Plugin::Moose::Role->new;
	$role->name($role_name);
	push @{$self->{program}->roles}, $role;

	$self->show_code_in_preview();
}

sub update_tree {
	my $self = shift;

	my $tree = $self->{tree};
	$tree->DeleteAllItems;

	my $program_node  = $tree->AddRoot(
		Wx::gettext('Program'),
		-1,
		-1,
		Wx::TreeItemData->new('')
	);

	for my $role (@{$self->{program}->roles}) {
		print "Adding " . $role->name . "\n";
		my $node = $tree->AppendItem(
			$program_node,
			$role->name,
			-1, -1,
			Wx::TreeItemData->new('')
			);
		$tree->Expand($node);
	}

	for my $class (@{$self->{program}->classes}) {
		print "Adding " . $class->name . "\n";
		my $node = $tree->AppendItem(
			$program_node,
			$class->name,
			-1, -1,
			Wx::TreeItemData->new('')
			);
		$tree->Expand($node);
	}
	
	$tree->ExpandAll;
}

sub on_add_attribute_button {
	my $self = shift;

	my $grid = $self->{grid};
	$grid->DeleteRows(0, $grid->GetNumberRows);
	$grid->InsertRows(0, 5);
	$grid->SetCellValue(0,0, Wx::gettext('Name:'));
	$grid->SetCellValue(1,0, Wx::gettext('Type:'));
	$grid->SetCellValue(2,0, Wx::gettext('Access:'));
	$grid->SetCellValue(3,0, Wx::gettext('Trigger:'));
	$grid->SetCellValue(4,0, Wx::gettext('Requires:'));
	for (3..4) {
		$grid->SetCellEditor($_, 1, Wx::GridCellBoolEditor->new);
		$grid->SetCellValue($_,1, 1) ;
	}
	$grid->Show(1);
	$self->Layout;
	$grid->SetFocus;
	$grid->SetGridCursor(0,1);

	$grid->SetCellValue(0,1, 'attribute' . $self->{attribute_count});
	$self->{attribute_count}++;
}

sub on_add_subtype_button {
	my $self = shift;

	my $grid = $self->{grid};
	$grid->DeleteRows(0, $grid->GetNumberRows);
	$grid->InsertRows(0, 3);
	$grid->SetCellValue(0,0, Wx::gettext('Name:'));
	$grid->SetCellValue(1,0, Wx::gettext('Constraint:'));
	$grid->SetCellValue(2,0, Wx::gettext('Error Message:'));
	$grid->Show(1);
	$self->Layout;
	$grid->SetFocus;
	$grid->SetGridCursor(0,1);

	$grid->SetCellValue(0,1, 'Subtype' . $self->{subtype_count});
	$self->{subtype_count}++;
}

sub on_insert_button_clicked {
	my $self = shift;

	$self->main->on_new;
	my $editor = $self->current->editor or return;
	$editor->insert_text($self->{preview}->GetText);
}

1;

# Copyright 2008-2012 The Padre development team as listed in Padre.pm.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.
