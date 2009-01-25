package Padre::Plugin::ConfigSync;

=pod

=head1 NAME

Padre::Plugin::ConfigSync - Padre configuration remote import and export

=head1 DESCRIPTION

This plugin provides the ability to import your Padre user configuration
file from a remote URL.

=cut

use 5.008;
use strict;
use warnings;
use Padre::Plugin 0.26 ();
use File::Spec         ();
use File::Temp         ();
use YAML::Tiny         ();
use Padre::Wx          ();
use Padre::Current     ();

our $VERSION = '0.25';
our @ISA     = 'Padre::Plugin';





######################################################################
# Configuration

sub plugin_name {
	return 'Config Remote Sync';
}

sub padre_interfaces {
	'Padre::Plugin'        => 0.26,
	'Padre::Config'        => 0.26,
	'Padre::Config::Human' => 0.26,
}





#####################################################################
# Plugin Interface

sub menu_plugin {
	$_[0]->plugin_name => [
		'Import Config URL' => 'config_import',
		'---'               => undef,
		'About'             => 'show_about',
	],
}





#####################################################################
# Implementation Methods

sub config_import {
	my $self = shift;

	# Ask what we should install
	my $dialog = Wx::TextEntryDialog->new(
		$main,
		"Enter URL to install\ne.g. http://svn.ali.as/users/adamk/config.yml",
		"pip",
		'',
	);
	if ( $dialog->ShowModal == Wx::wxID_CANCEL ) {
		return;
	}
	my $string = $dialog->GetValue;
	$dialog->Destroy;
	unless ( defined $string and $string =~ /\S/ ) {
		$main->error("Did not provide a distribution");
		return;
	}

	die "CODE INCOMPLETE";
}

sub show_about {
	my $self = shift;

	# Locate this plugin
	my $path = File::Spec->catfile(
		Padre::Config->default_dir,
		qw{ plugins Padre Plugin My.pm }
	);

	# Generate the About dialog
	my $about = Wx::AboutDialogInfo->new;
	$about->SetName("My Plugin");
	$about->SetDescription( <<"END_MESSAGE" );
The philosophy behind Padre is that every Perl programmer
should be able to easily modify and improve their own editor.

To help you get started, we've provided you with your own plugin.

It is located in your configuration directory at:
$path
Open it with with Padre and you'll see an explanation on how to add items.
END_MESSAGE

	# Show the About dialog
	Wx::AboutBox( $about );

	return;
}

=pod

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Padre-Plugin-ConfigSync>

For other issues, or commercial enhancement or support, contact the author.

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2008 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
