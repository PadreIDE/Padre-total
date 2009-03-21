package Padre::Plugin::ClassSniff;

use 5.008;
use warnings;
use strict;

use Padre::Config ();
use Padre::Wx     ();
use Padre::Plugin ();
use Padre::Util   ();

our $VERSION = '0.01';
our @ISA     = 'Padre::Plugin';

=head1 NAME

Padre::Plugin::ClassSniff - Simple Class::Sniff interface for Padre

=head1 SYNOPSIS

Use this like any other Padre plugin. To install
Padre::Plugin::ClassSniff for your user only, you can
type the following in the extracted F<Padre-Plugin-ClassSniff-...>
directory:

  perl Makefile.PL
  make
  make test
  make installplugin

Afterwards, you can enable the plugin from within Padre
via the menu I<Plugins-E<gt>Plugin Manager> and there click
I<enable> for I<Class::Sniff>.

=head1 DESCRIPTION

This module adds very, very basic support for running Class::Sniff
with the default settings against the document (assumed to be a class)
in the current editor tab.

The output will go to the Padre output window.

TODO: Configuration

=cut


sub padre_interfaces {
	'Padre::Plugin' => 0.24,
	'Padre::Task' => 0.29,
}

sub plugin_name {
	'Class::Sniff';
}

sub menu_plugins_simple {
	my $self = shift;
	return $self->plugin_name => [
		'About'             => sub { $self->show_about },
		'Print Report'      => sub { $self->print_report },
#		'Configuration'     => sub { $self->configuration_dialog(Padre->ide->wx) },
	];
}

sub print_report {
	my $self = shift;
	push @INC, '/home/tsee/padre/trunk/Padre-Plugin-ClassSniff/lib';
	require Padre::Task::ClassSniff;
	Padre::Task::ClassSniff->new(
		mode => 'print_report',
	)->schedule();
}



sub show_about {
	my $self = shift;

	# Generate the About dialog
	my $about = Wx::AboutDialogInfo->new;
	$about->SetName("Padre::Plugin::ClassSniff");
	$about->SetDescription( <<"END_MESSAGE" );
Initial Class::Sniff support for Padre
END_MESSAGE
	$about->SetVersion( $VERSION );

	# Show the About dialog
	Wx::AboutBox( $about );

	return;
}

#sub plugin_preferences {
#	my $self = shift;
#	my $wxparent = shift;
#}


1;

__END__


=head1 AUTHOR

Steffen Mueller, C<< <smueller at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to L<http://padre.perlide.org/>

=head1 COPYRIGHT & LICENSE

Copyright 2009 The Padre development team as listed in Padre.pm.
all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

# Copyright 2009 The Padre development team as listed in Padre.pm.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.
