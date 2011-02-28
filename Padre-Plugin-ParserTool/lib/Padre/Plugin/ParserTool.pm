package Padre::Plugin::ParserTool;

=pod

=head1 NAME

Padre::Plugin::ParserTool - A realtime interactive parser test tool for Padre

=head1 DESCRIPTION

The B<ParserTool> plugin adds an interactive parser testing tool for L<Padre>.

It provides a two-panel dialog where you can type file contents into a panel
on one side, and see a realtime dump of the resulting parsed structure on the
other side of the dialog.

The dialog is configurable, so it can be used to test both common Perl parsers
and parsers for custom file formats of your own.

=head1 METHODS

=cut

use 5.008005;
use strict;
use warnings;
use Padre::Plugin ();

our $VERSION = '0.01';
our @ISA     = 'Padre::Plugin';





######################################################################
# Configuration Methods

sub plugin_name {
	'Parser Tool';
}

sub padre_interfaces {
	'Padre::Plugin'   => '0.81',
	'Padre::Document' => '0.81',
	'Padre::Wx'       => '0.81',
}

sub menu_plugins_simple {
	my $self = shift;
	return $self->plugin_name => [
		'Parser Tool' => sub {
			$self->show_dialog;
		},
		'---' => undef,
		'About'   => sub {
			$self->show_about;
		},
	];
}

sub plugin_disable {
	my $self = shift;

	# Unload any child modules we loaded
	$self->unload( qw{
		Padre::Plugin::ParserTool::Dialog
		Padre::Plugin::ParserTool::FBP
	} );

	$self->SUPER::plugin_disable(@_);
}





######################################################################
# Main Methods

sub show_about {
	die "CODE INCOMPLETE";
}

sub show_dialog {
	my $self = shift;
	my $main = $self->main;

	# Spawn the dialog
	require Padre::Plugin::ParserTool::Dialog;
	Padre::Plugin::ParserTool::Dialog->new($main)->ShowModal;

	return;
}

1;


=pod

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Padre-Plugin-ParserTool>

For other issues, or commercial enhancement or support, contact the author.

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 SEE ALSO

L<Padre>

=head1 COPYRIGHT

Copyright 2011 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
