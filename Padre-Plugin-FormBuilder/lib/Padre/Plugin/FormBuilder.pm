package Padre::Plugin::FormBuilder;

=pod

=head1 NAME

Padre::Plugin::FormBuilder - Generate Perl for dialogs created in wxFormBuilder

=head1 DESCRIPTION

The FormBuilder user interface design tool helps to produce user interface code
relatively quickly. However, it does not support the generation of Perl.

B<Padre::Plugin::FormBuilder> provides an interface to the
L<Wx::Perl::FormBuilder> module to allow the generation of Padre dialog code
based on wxFormBuilder designs.

=head1 METHODS

=cut

use 5.008005;
use strict;
use warnings;
use Params::Util  1.00 ();
use Padre::Wx          ();
use Padre::Plugin 0.65 ();

our $VERSION = '0.02';
our @ISA     = 'Padre::Plugin';





#####################################################################
# Padre::Plugin Methods

sub padre_interfaces {
	'Padre::Plugin' => 0.65,
	'Padre::Task'   => 0.65,
}

sub plugin_name {
	'wxFormBuilder';
}

# Clean up our classes
sub plugin_disable {
	require Class::Unload;
	Class::Unload->unload('Padre::Plugin::FormBuilder::Perl');
	Class::Unload->unload('Padre::Plugin::FormBuilder::Dialog');
}

sub menu_plugins_simple {
	my $self = shift;
	return $self->plugin_name => [
		'Generate Dialog' => sub {
			$self->menu_new_dialog_perl;
		},
	];
}





######################################################################
# Menu Commands

sub menu_new_dialog_perl {
	my $self = shift;
	my $main = $self->main;

	# Load the wxGlade-generated Perl file
	my $fbp = $self->dialog_fbp or return;

	# Which package do they want?
	my $list = $self->package_list($fbp);
	my $name = $self->dialog_function($list) or return;

	# Convert to the final class
	my $new = $self->dialog_class(
		Params::Util::_IDENTIFIER($name) ? "Padre::Wx::Dialog::$name" : $name
	) or return;

	# Create the dialog
	$self->generate_dialog( $fbp, $name, $new );

	return;
}





######################################################################
# Dialog Functions

sub dialog_fbp {
	my $self = shift;
	my $main = $self->main;

	# Where is the wxGlade-generated Perl file
	my $dialog = Wx::FileDialog->new(
		$main,
		Wx::gettext("Select wxFormBuilder File"),
		$main->cwd,
		"",
		"*.fbp",
		Wx::wxFD_OPEN | Wx::wxFD_FILE_MUST_EXIST,
	);
	$dialog->CenterOnParent;

	# File select loop
	while ( $dialog->ShowModal != Wx::wxID_CANCEL ) {
		# Check the file
		my $path = $dialog->GetPath;
		unless ( -f $path ) {
			$main->error("File '$path' does not exist");
			next;
		}

		return $path;
	}

	return;
}

sub dialog_function {
	my $self = shift;
	my $main = $self->main;

	# Single choice dialog
	my $dialog = Wx::SingleChoiceDialog->new(
		$main,
		Wx::gettext('Select Dialog Package'),
		$self->plugin_name,
		$_[0], # Package ARRAY reference
		undef,
		Wx::wxDEFAULT_DIALOG_STYLE
		| Wx::wxOK
		| Wx::wxCANCEL,
	);
	$dialog->CenterOnParent;

	my $rv = $dialog->ShowModal;
	if ( $rv == Wx::wxID_OK ) {
		return $dialog->GetStringSelection;
	}

	return;
}

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





######################################################################
# Main Functionality

# Do a simple scan for package statements
sub package_list {
	my $self = shift;
	my $file = shift;

	# Load the file
	require FBP;
	my $fbp = FBP->new;
	my $ok  = $fbp->parse_file($file);
	unless ( $ok ) {
		$self->main->error("Failed to load $file");
		return;
	}

	return [
		grep { defined $_ and length $_ }
		map  { $_->name }
		$fbp->find( isa => 'FBP::Dialog' )
	];
}

# Generate the class code
sub generate_dialog {
	my $self = shift;
	my $file = shift;
	my $name = shift;
	my $pkg  = shift;

	# Load the file
	require FBP;
	my $fbp = FBP->new;
	my $ok  = $fbp->parse_file($file);
	unless ( $ok ) {
		$self->main->error("Failed to load $file");
		return;
	}

	# Find the dialog
	my $project = $fbp->find_first(
		isa  => 'FBP::Project',
	);
	my $dialog = $project->find_first(
		isa  => 'FBP::Dialog',
		name => $name,
	);
	unless ( $dialog ) {
		$self->main->error("Failed to find dialog $name");
		return;
	}

	# Generate the perl dialog code
	require Padre::Plugin::FormBuilder::Perl;
	my $perl = Padre::Plugin::FormBuilder::Perl->new(
		project => $project,
	);
	my $string = $perl->flatten(
		$perl->dialog_class($dialog)
	);

	# Open the generated code as a new file
	$self->main->new_document_from_string(
		$string,
		'application/x-perl',
	);

	return;
}

1;

=pod

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Padre-Plugin-FormBuilder>

For other issues, or commercial enhancement or support, contact the author.

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 SEE ALSO

L<Padre>

=head1 COPYRIGHT

Copyright 2010 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
