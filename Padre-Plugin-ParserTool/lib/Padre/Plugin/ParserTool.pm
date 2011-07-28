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

sub menu_plugins {
	my $self = shift;
	my $main = shift;

	# Create a manual menu item
	my $item = Wx::MenuItem->new(
		undef,
		-1,
		$self->plugin_name,
	);
	Wx::Event::EVT_MENU(
		$main,
		$item,
		sub {
			local $@;
			eval {
				$self->menu_dialog($main);
			};
		},
	);

	return $item;
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

sub menu_dialog {
	my $self = shift;
	my $main = shift;

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
