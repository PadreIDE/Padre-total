package Padre::Plugin::FormBuilder::Dialog;

use 5.008;
use strict;
use warnings;
use Class::Unload                   ();
use Class::Inspector                ();
use Padre::Plugin::FormBuilder::FBP ();

our $VERSION = '0.01';
our @ISA     = 'Padre::Plugin::FormBuilder::FBP';

# Temporary namespace counter
my $COUNT = 0;





######################################################################
# Customisation

sub new {
	my $class = shift;
	my $main  = shift;

	# Create the dialog
	my $self = $class->SUPER::new($main);
	$self->SetTitle("Padre FormBuilder");
	$self->CenterOnParent;

	# Disable the form elements initially useless
	$self->{select}->Disable;
	$self->{preview}->Disable;
	$self->{associate}->Disable;
	$self->{generate}->Disable;
	$self->{padre}->Disable;

	# Update the form elements
	$self->{file}->SetLabel("Select Source:");

	# If any of the dialogs are under Padre:: default the
	# Padre-compatible code generation to true.
	# if ( grep { /^Padre::/ } @$dialogs ) {
		# $self->{padre}->SetValue(1);
	# }

	# If we don't have a current project, disable the checkbox
	my $project = $main->current->project;
	unless ( $project and $project->isa('Padre::Project::Perl') ) {
		$self->{associate}->Disable;
	}

	return $self;
}

sub path {
	$_[0]->{browse}->GetPath;
}

sub selected {
	$_[0]->{select}->GetStringSelection;
}

sub padre {
	!! $_[0]->{padre}->IsChecked;
}




######################################################################
# Event Handlers

sub browse_changed {
	my $self = shift;
	my $path = $self->path;

	# Flush any existing state
	$self->{xml} = undef;
	$self->{select}->Clear;
	$self->{select}->Disable;
	$self->{preview}->Disable;
	$self->{associate}->Disable;
	$self->{generate}->Disable;
	$self->{padre}->Disable;

	# Attempt to load the file and parse out the dialog list
	local $@;
	eval {
		# Load the file
		require FBP;
		$self->{xml} = FBP->new;
		my $ok = $self->{xml}->parse_file($path);
		die "Failed to load the file" unless $ok;

		# Extract the dialog list
		my $list = [
			grep { defined $_ and length $_ }
			map  { $_->name }
			$self->{xml}->find( isa => 'FBP::Dialog' )
		];
		die "No dialogs found" unless @$list;

		# Populate the dialog list
		$self->{select}->Append($list);
		$self->{select}->SetSelection(0);

		# Enable the dialog list and buttons
		$self->{select}->Enable;
		$self->{preview}->Enable;
		$self->{associate}->Enable;
		$self->{generate}->Enable;
		$self->{padre}->Enable;

		# Indicate the FBP file is ok
		if ( $self->{browse}->HasTextCtrl ) {
			my $ctrl = $self->{browse}->GetTextCtrl;
			$ctrl->SetBackgroundColour(
				Wx::Colour->new('#CCFFCC')
			);
		}
	};
	if ( $@ ) {
		# Indicate the FBP file is not ok
		if ( $self->{browse}->HasTextCtrl ) {
			my $ctrl = $self->{browse}->GetTextCtrl;
			$ctrl->SetBackgroundColour(
				Wx::Colour->new('#FFCCCC')
			);
		}

		# Inform the user directly
		$self->main->error("Missing, invalid or empty file '$path'");
	}

	return;
}

sub generate {
	my $self = shift;
	my $name = $self->selected or return;
	my $xml  = $self->{xml}    or return;

	# Generate the dialog code
	my $code = $self->generate_dialog(
		xml     => $self->{xml},
		dialog  => $name,
		package => $name,
		padre   => $self->padre,
	);

	# Open the generated code as a new file
	$self->main->new_document_from_string(
		$code => 'application/x-perl',
	);

	return;
}

sub preview {
	my $self = shift;
	my $name = $self->selected or return;
	my $xml  = $self->{xml}    or return;

	# Generate the dialog code
	my $code = $self->generate_dialog(
		xml     => $self->{xml},
		dialog  => $name,
		package => "Padre::Plugin::FormBuilder::Temp::Dialog" . ++$COUNT,
		padre   => $self->padre,
	);

	# Load the dialog
	local $@;
	eval "$code";
	if ( $@ ) {
		$self->main->error("Error loading dialog: $@");
		$self->unload($name);
		last;
	}

	# Create the dialog
	my $preview = eval {
		$name->new( $self->main );
	};
	if ( $@ ) {
		$self->main->error("Error constructing dialog: $@");
		$self->unload($name);
		last;
	}

	# Show the dialog
	my $rv = eval {
		$preview->ShowModal;
	};
	$preview->Destroy;
	if ( $@ ) {
		$self->main->error("Dialog crashed while in use: $@");
		$self->unload($name);
		last;
	}

	# Clean up
	$self->unload($name);

	return;
}





######################################################################
# Support Methods

# Generate the class code
sub generate_dialog {
	my $self  = shift;
	my %param = @_;

	# Find the dialog
	my $fbp = $param{xml}->find_first(
		isa  => 'FBP::Project',
	);
	my $dialog = $fbp->find_first(
		isa  => 'FBP::Dialog',
		name => $param{dialog},
	);
	unless ( $dialog ) {
		$self->main->error("Failed to find dialog $param{dialog}");
		return;
	}

	# Does the project have an existing version?
	my $project = $self->current->project;
	my $version = $project ? $project->version : undef;

	# Configure the code generator
	my $perl = undef;
	if ( $param{padre} ) {
		require Padre::Plugin::FormBuilder::Perl;
		$perl = Padre::Plugin::FormBuilder::Perl->new(
			project => $fbp,
			defined($version) ? ( version => $version ) : (),
		);
	} else {
		require FBP::Perl;
		$perl = FBP::Perl->new(
			project => $fbp,
		);
	}

	# Generate the class code
	my $string = $perl->flatten(
		$perl->dialog_class( $dialog, $param{package} )
	);

	return $string;
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
			$main->error("Did not provide a class name");
			next;
		}
		unless ( Params::Util::_CLASS($package) ) {
			$main->error("Not a valid class name");
			next;
		}

		return $package;
	}

	return;
}

# Convenience integration with Class::Unload
sub unload {
	require Class::Unload;
	my $either = shift;
	foreach my $package (@_) {
		Class::Unload->unload($package);
	}
	return 1;
}

1;
