package Padre::Plugin::Moose::Main;

use 5.008;
use strict;
use warnings;
use Padre::Plugin::Moose::FBP::Main ();

our $VERSION = '0.04';
our @ISA     = qw{
	Padre::Plugin::Moose::FBP::Main
};


my %INSPECTOR = (
    
    'Class' => [
        { name => Wx::gettext('Name:') },
        { name => Wx::gettext('Superclass:') },
        { name => Wx::gettext('Roles:') },
        { name => Wx::gettext('Clean namespace?'), is_bool => 1 },
        { name => Wx::gettext('Make Immutable?'), is_bool => 1 }
    ],

    'Role' => [
        { name => Wx::gettext('Name:') },
        { name => Wx::gettext('Requires:') },
    ],

    'Attribute' => [
        { name => Wx::gettext('Name:') },
        { name => Wx::gettext('Type:') },
        { name => Wx::gettext('Access:') },
        { name => Wx::gettext('Trigger:'), is_bool => 1 },
        { name => Wx::gettext('Requires:'), is_bool => 1 }
    ],

    'Subtype' => [
        { name => Wx::gettext('Name:') },
        { name => Wx::gettext('Type:') },
        { name => Wx::gettext('Error Message:') },
    ],

    'Method' => [
        { name => Wx::gettext('Name:') },
    ],
);

sub new {
	my $class = shift;
	my $main  = shift;

	my $self = $class->SUPER::new($main);
	$self->CenterOnParent;

	$self->{class_count} = 1;
	$self->{role_count} = 1;
	$self->{attribute_count} = 1;
	$self->{subtype_count} = 1;
	$self->{method_count} = 1;
	
	require Padre::Plugin::Moose::Program;
	$self->{program} = Padre::Plugin::Moose::Program->new;
	$self->{current_element} = undef;

	# Defaults
	$self->{comments_checkbox}->SetValue(1);
	$self->{sample_code_checkbox}->SetValue(1);
	$self->{add_attribute_button}->Enable(0);
	$self->{add_subtype_button}->Enable(0);
	$self->{add_method_button}->Enable(0);
	
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
	Wx::AboutBox($about);

	return;
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
			my $element   = $tree->GetPlData($item) or return;

			my $is_class = $element->isa('Padre::Plugin::Moose::Class');
			$self->{add_attribute_button}->Enable($is_class);
			$self->{add_subtype_button}->Enable($is_class);
			$self->{add_method_button}->Enable($is_class);
			$self->show_inspector($element);
			$self->{current_element} = $element;
		}
	);

	for my $role (@{$program->roles}) {
		my $node = $tree->AppendItem(
			$program_node,
			$role->name,
			-1, -1,
			Wx::TreeItemData->new($role)
			);
		$tree->Expand($node);
	}

	for my $class (@{$program->classes}) {
		my $node = $tree->AppendItem(
			$program_node,
			$class->name,
			-1, -1,
			Wx::TreeItemData->new($class)
			);
			
		for my $attribute (@{$class->attributes}) {
			$tree->AppendItem(
				$node,
				$attribute->name,
				-1, -1,
				Wx::TreeItemData->new($attribute)
			);
		}

		for my $subtype (@{$class->subtypes}) {
			$tree->AppendItem(
				$node,
				$subtype->name,
				-1, -1,
				Wx::TreeItemData->new($subtype)
			);
		}

		for my $method (@{$class->methods}) {
			$tree->AppendItem(
				$node,
				$method->name,
				-1, -1,
				Wx::TreeItemData->new($method)
			);
		}

		$tree->Expand($node);
	}
	
	$tree->ExpandAll;
}

sub show_inspector {
	my $self = shift;
	my $element = shift;

	require Scalar::Util;
	my $type = Scalar::Util::blessed($element);
	if((not defined $type) or ($type !~ /(Class|Role|Attribute|Subtype|Method)$/)) {
		die "type: $element is not Class, Role, Attribute, Subtype or Method\n";
	}
	$type =~ s/.+?(Class|Role|Attribute|Subtype|Method)$/$1/g;

	my $rows = $INSPECTOR{$type};
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

	$grid->SetCellValue(0, 1, $element->name);
}

sub on_add_class_button {
	my $self = shift;

	my $class_name = "Class" . $self->{class_count}++;

	# Add a new class object to program
	require Padre::Plugin::Moose::Class;
	my $class = Padre::Plugin::Moose::Class->new;
	$class->name($class_name);
	$class->immutable(1);
	$class->namespace_autoclean(1);
	push @{$self->{program}->classes}, $class;
	
	$self->show_inspector( $class );

	$self->show_code_in_preview();
}

sub on_add_role_button {
	my $self = shift;
	
	my $role_name = "Role" . $self->{role_count}++;
	
	# Add a new role object to program
	require Padre::Plugin::Moose::Role;
	my $role = Padre::Plugin::Moose::Role->new;
	$role->name($role_name);
	push @{$self->{program}->roles}, $role;
	
	$self->show_inspector( $role );

	$self->show_code_in_preview();
}

sub on_add_attribute_button {
	my $self = shift;

	return unless defined $self->{current_element};
	return unless $self->{current_element}->isa('Padre::Plugin::Moose::Class');

	

	my $attribute_name = 'attribute' . $self->{attribute_count}++;
	
	# Add a new attribute object to class
	require Padre::Plugin::Moose::Attribute;
	my $attribute = Padre::Plugin::Moose::Attribute->new;
	$attribute->name($attribute_name);
	push @{$self->{current_element}->attributes}, $attribute;
	
	$self->show_inspector( $attribute );

	$self->show_code_in_preview();
}

sub on_add_subtype_button {
	my $self = shift;

	return unless defined $self->{current_element};
	return unless $self->{current_element}->isa('Padre::Plugin::Moose::Class');


	my $subtype_name = 'Subtype' . $self->{subtype_count}++;

	# Add a new subtype object to class
	require Padre::Plugin::Moose::Subtype;
	my $subtype = Padre::Plugin::Moose::Subtype->new;
	$subtype->name($subtype_name);
	push @{$self->{current_element}->subtypes}, $subtype;

	$self->show_inspector( $subtype );

	$self->show_code_in_preview();
}

sub on_add_method_button {
	my $self = shift;

	return unless defined $self->{current_element};
	return unless $self->{current_element}->isa('Padre::Plugin::Moose::Class');

	my $method_name = 'method_' . $self->{method_count}++;

	# Add a new method object to class
	require Padre::Plugin::Moose::Method;
	my $method = Padre::Plugin::Moose::Method->new;
	$method->name($method_name);
	push @{$self->{current_element}->methods}, $method;

	$self->show_inspector( $method );

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
