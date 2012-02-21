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

	my $data = [{name => Wx::gettext('Name:')},
			{name => Wx::gettext('Superclass:')},
			{name => Wx::gettext('Roles:')},
			{name => Wx::gettext('Clean namespace?'), is_bool => 1},
			{name =>  Wx::gettext('Make Immutable?'), is_bool => 1}];
	$self->setup_inspector( $data );

	my $class_name = "Class" . $self->{class_count};
	$self->{grid}->SetCellValue(0,1, $class_name);
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
	
	my $data = [{name => Wx::gettext('Name:')},
			{name => Wx::gettext('Requires:')}, ];
	$self->setup_inspector( $data );

	my $role_name = "Role" . $self->{role_count};
	$self->{grid}->SetCellValue(0,1, $role_name);
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

	my $program = $self->{program};
	my $program_node  = $tree->AddRoot(
		Wx::gettext('Program'),
		-1,
		-1,
		Wx::TreeItemData->new($program)
	);

	# Set up the events
	Wx::Event::EVT_TREE_SEL_CHANGED(
		$tree, $tree,
		
		sub {
	my $item   = $_[1]->GetItem         or return;
	my $data   = $tree->GetPlData($item) or return;
			use Data::Dumper;
			
			print Dumper($data);
			#print "activated: " . $_[1]->GetItem . "\n";
		}
	);

	for my $role (@{$self->{program}->roles}) {
		my $node = $tree->AppendItem(
			$program_node,
			$role->name,
			-1, -1,
			Wx::TreeItemData->new($role)
			);
		$tree->Expand($node);
	}

	for my $class (@{$self->{program}->classes}) {
		my $node = $tree->AppendItem(
			$program_node,
			$class->name,
			-1, -1,
			Wx::TreeItemData->new($class)
			);
		$tree->Expand($node);
	}
	
	$tree->ExpandAll;
}

sub setup_inspector {
	my $self = shift;
	my $rows = shift;
	
	my $grid = $self->{grid};
	$grid->DeleteRows(0, $grid->GetNumberRows);
	$grid->InsertRows(0, scalar @$rows);
	my $row_index = 0;
	for my $row (@$rows) {
		$grid->SetCellValue($row_index,0, $row->{name});
		if(defined $row->{is_bool}) {
			$grid->SetCellEditor($row_index, 1, Wx::GridCellBoolEditor->new);
			$grid->SetCellValue($row_index,1, 1) ;
		}
		$row_index++;
	}
	$grid->Show(1);
	$self->Layout;
	$grid->SetFocus;
	$grid->SetGridCursor(0, 1);
}
sub on_add_attribute_button {
	my $self = shift;

	my $data = [{name => Wx::gettext('Name:')},
			{name => Wx::gettext('Type:')},
			{name => Wx::gettext('Access:')},
			{name => Wx::gettext('Trigger:'), is_bool => 1},
			{name =>  Wx::gettext('Requires:'), is_bool => 1}];
	$self->setup_inspector( $data );

	my $attribute_name = 'attribute' . $self->{attribute_count};
	$self->{grid}->SetCellValue(0,1, $attribute_name);
	$self->{attribute_count}++;
	
	# Add a new attribute object to program
	my $attribute = Padre::Plugin::Moose::Attribute->new;
	$attribute->name($attribute_name);
	push @{$self->{program}->roles}, $attribute;

	$self->show_code_in_preview();
}

sub on_add_subtype_button {
	my $self = shift;

	my $data = [{name => Wx::gettext('Name:')},
			{name => Wx::gettext('Type:')},
			{name => Wx::gettext('Error Message:')}, ];
	$self->setup_inspector( $data );

	my $subtype_name = 'Subtype' . $self->{subtype_count};
	$self->{grid}->SetCellValue(0,1, $subtype_name);
	$self->{subtype_count}++;

	# Add a new subtype object to program
	my $subtype = Padre::Plugin::Moose::Attribute->new;
	$subtype->name($subtype_name);
	push @{$self->{program}->roles}, $subtype;

	$self->show_code_in_preview();
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
