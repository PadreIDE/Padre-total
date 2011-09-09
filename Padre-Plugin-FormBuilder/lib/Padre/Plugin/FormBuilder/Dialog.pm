package Padre::Plugin::FormBuilder::Dialog;

use 5.008;
use strict;
use warnings;
use Class::Inspector                    ();
use Padre::Unload                       ();
use Padre::Plugin::FormBuilder::FBP     ();
use Padre::Plugin::FormBuilder::Preview ();

our $VERSION = '0.04';
our @ISA     = 'Padre::Plugin::FormBuilder::FBP';

# Temporary namespace counter
my $COUNT = 0;

use constant OPTIONS => qw{
	translate
	encapsulation
	version
	padre
};

use constant SINGLE => qw{
	select
	preview
	translate
	encapsulation
	version
	associate
	generate
};





######################################################################
# Customisation

sub new {
	my $class = shift;
	my $main  = shift;

	# Create the dialog
	my $self = $class->SUPER::new($main);
	$self->disable( OPTIONS, SINGLE );
	$self->CenterOnParent;

	# If we don't have a current project, disable the checkbox
	my $project = $main->current->project;
	unless ( $project and $project->isa('Padre::Project::Perl') ) {
		$self->associate->Disable;
	}

	return $self;
}

sub path {
	$_[0]->browse->GetPath;
}

sub selected {
	$_[0]->select->GetStringSelection;
}

sub padre_code {
	!! $_[0]->padre->IsChecked;
}

sub i18n {
	$_[0]->translate->GetSelection > 0;
}

sub i18n_trim {
	$_[0]->translate->GetSelection > 1;
}

sub encapsulate {
	$_[0]->encapsulation->GetSelection == 1;
}





######################################################################
# Event Handlers

sub browse_changed {
	my $self = shift;
	my $path = $self->path;

	# Flush any existing state
	$self->{xml} = undef;
	$self->select->Clear;
	$self->disable( OPTIONS, SINGLE );

	# Attempt to load the file and parse out the dialog list
	local $@;
	eval {
		# This might take a little while
		my $lock = $self->main->lock('UPDATE');

		# Load the file
		require FBP;
		$self->{xml} = FBP->new;
		my $ok = $self->{xml}->parse_file($path);
		die "Failed to load the file" unless $ok;

		# Extract the dialog list
		my $list = [
			grep { defined $_ and length $_ }
			map  { $_->name }
			$self->{xml}->project->forms
		];
		die "No dialogs found" unless @$list;

		# Populate the dialog list
		$self->select->Append($list);
		$self->select->SetSelection(0);

		# If any of the dialogs are under Padre:: default the
		# Padre-compatible code generation to true.
		if ( grep { /^Padre::/ } @$list ) {
			$self->padre->SetValue(1);
			$self->encapsulation->SetSelection(0);
			$self->translate->SetSelection(2);
		} else {
			$self->padre->SetValue(0);
			$self->encapsulation->SetSelection(0);
			$self->translate->SetSelection(0);
		}

		# Enable the dialog list and buttons
		$self->enable( OPTIONS, SINGLE );

		# Indicate the FBP file is ok
		if ( $self->browse->HasTextCtrl ) {
			my $ctrl = $self->browse->GetTextCtrl;
			$ctrl->SetBackgroundColour(
				Wx::Colour->new('#CCFFCC')
			);
		}
	};
	if ( $@ ) {
		# Indicate the FBP file is not ok
		if ( $self->browse->HasTextCtrl ) {
			$self->browse->GetTextCtrl->SetBackgroundColour(
				Wx::Colour->new('#FFCCCC')
			);
		}

		# Inform the user directly
		$self->error("Missing, invalid or empty file '$path': $@");
	}

	return;
}

sub generate_clicked {
	my $self   = shift;
	my $dialog = $self->selected or return;
	my $fbp    = $self->{xml}    or return;
	my $form   = $fbp->form($dialog);
	unless ( $form ) {
		$self->error("Failed to find form $dialog");
		return;
	}

	# Generate the dialog code
	my $code = $self->generate_form(
		fbp       => $fbp,
		form      => $form,
		package   => $dialog,
		padre     => $self->padre_code,
		version   => $self->version->GetValue || '0.01',
		i18n      => $self->i18n,
		i18n_trim => $self->i18n_trim,
	) or return;

	# Open the generated code as a new file
	$self->main->new_document_from_string(
		$code => 'application/x-perl',
	);

	return;
}

sub preview_clicked {
	my $self   = shift;
	my $dialog = $self->selected or return;
	my $fbp    = $self->{xml}    or return;
	my $form   = $fbp->form($dialog);
	unless ( $form ) {
		$self->error("Failed to find form $dialog");
		return;
	}

	# Close any previous frame
	$self->clear_preview;

	# Generate the dialog code
	my $name = "Padre::Plugin::FormBuilder::Temp::Dialog" . ++$COUNT;
	SCOPE: {
		local $@ = '';
		my $code = eval {
			$self->generate_form(
				fbp       => $fbp,
				form      => $form,
				package   => $name,
				padre     => $self->padre_code,
				version   => $self->version->GetValue || '0.01',
				i18n      => 0,
				i18n_trim => 0,
			)
		};
		if ( $@ or not $code ) {
			$self->error("Error generating dialog: $@");
			$self->unload($name);
			return;
		}

		# Load the dialog
		eval "$code";
		if ( $@ ) {
			$self->error("Error loading dialog: $@");
			$self->unload($name);
			return;
		}
	}

	# Create the form
	local $@;
	my $preview = eval {
		$form->isa('FBP::FormPanel')
			? Padre::Plugin::FormBuilder::Preview->new( $self->main, $name )
			: $name->new( $self->main )
	};
	if ( $@ ) {
		$self->error("Error constructing dialog: $@");
		$self->unload($name);
		return;
	}

	# Handle the ones we can show modally
	if ( $preview->can('ShowModal') ) {
		# Show the dialog
		my $rv = eval {
			$preview->ShowModal;
		};
		$preview->Destroy;
		if ( $@ ) {
			$self->error("Dialog crashed while in use: $@");
		}
		$self->unload($name);
		return;
	}

	# Show the long way
	$preview->Show;
	$self->{frame} = $preview->GetId;

	return 1;
}





######################################################################
# Support Methods

# Generate the class code
sub generate_form {
	my $self  = shift;
	my %param = @_;

	# Configure the code generator
	my $perl = undef;
	if ( $param{padre} ) {
		require Padre::Plugin::FormBuilder::Perl;
		$perl = Padre::Plugin::FormBuilder::Perl->new(
			project     => $param{fbp}->project,
			version     => $param{version},
			encapsulate => $self->encapsulate,
			prefix      => 2,
			nocritic    => 1,
			i18n        => $param{i18n},
			i18n_trim   => $param{i18n_trim},
		);
	} else {
		require FBP::Perl;
		$perl = FBP::Perl->new(
			project   => $param{fbp}->project,
			nocritic  => 1,
			i18n      => $param{i18n},
			i18n_trim => $param{i18n_trim},
		);
	}

	# Generate the class code
	local $@;
	my $string = eval {
		$perl->flatten(
			$perl->form_class( $param{form} )
		);
	};
	if ( $@ ) {
		$self->error("Code Generator Error: $@");
		return;
	}

	# Customise the package name if requested
	if ( $param{package} ) {
		$string =~ s/^package [\w:]+/package $param{package}/;
	}

	return $string;
}

sub clear_preview {
	my $self = shift;
	if ( $self->{frame} ) {
		my $old = Wx::Window::FindWindowById( delete $self->{frame} );
		$old->Destroy if $old;
	}
	return 1;
}

# NOTE: Not in use yet, intended for arbitrary class entry later
sub dialog_class {
	my $self = shift;
	my $name = shift || '';
	my $main = $self->main;

	# What class name?
	my $dialog = Wx::TextEntryDialog->new(
		$main,
		Wx::gettext("Enter Class Name"),
		$self->plugin_name,
		$name,
	);
	while ( $dialog->ShowModal != Wx::wxID_CANCEL ) {
		my $package = $dialog->GetValue;
		unless ( defined $package and length $package ) {
			$self->error("Did not provide a class name");
			next;
		}
		unless ( Params::Util::_CLASS($package) ) {
			$self->error("Not a valid class name");
			next;
		}

		return $package;
	}

	return;
}

# Enable a set of controls
sub enable {
	my $self = shift;
	foreach my $name ( @_ ) {
		$self->$name()->Enable(1);
	}
	return;
}

# Disable a set of controls
sub disable {
	my $self = shift;
	foreach my $name ( @_ ) {
		$self->$name()->Disable;
	}
	return;
}

# Convenience integration with Class::Unload
sub unload {
	my $either = shift;
	foreach my $package (@_) {
		Padre::Unload::unload($package);
	}
	return 1;
}

# Convenience
sub error {
	shift->main->error(@_);
}

1;

# Copyright 2008-2011 The Padre development team as listed in Padre.pm.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.
