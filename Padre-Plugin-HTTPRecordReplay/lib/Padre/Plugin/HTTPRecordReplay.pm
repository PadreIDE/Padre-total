package Padre::Plugin::HTTPRecordReplay;

use 5.008;
use strict;
use warnings;
use Padre::Config ();
use Padre::Wx     ();
use Padre::Plugin ();

our $VERSION = '0.01';
our @ISA     = 'Padre::Plugin';

=head1 NAME

Padre::Plugin::HTTPRecordReplay - using Sniffer::HTTP to record HTTP sessions

=head1 WARNING

Experimental code ahead

=head1 DESCRIPTION

Using the Sniffer::HTTP sniffer to record HTTP sessions.

As Sniffer::HTTPis working in promiscuous mode when running on Unix 
or Linux we will have to run this as root. In order not to run Padre
as root we execute a separate script using sudo. That will require 
authentication.

=head1 COPYRIGHT

Copyright 2009 Gabor Szabo. L<http://www.szabgab.com/>

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl 5 itself.

=cut


#####################################################################
# Padre::Plugin Methods

sub padre_interfaces {
	'Padre::Plugin' => 0.24
}

sub plugin_name {
	'HTTP Sniffer';
}

sub menu_plugins_simple {
	my $self = shift;
	return $self->plugin_name => [
		'About' => sub { $self->show_about },
		'Sniff' => sub { $self->sniff },

		# 'Another Menu Entry' => sub { $self->about },
		# 'A Sub-Menu...' => [
		#     'Sub-Menu Entry' => sub { $self->about },
		# ],
	];
}





#####################################################################
# Custom Methods

sub show_about {
	my $self = shift;

	# Generate the About dialog
	my $about = Wx::AboutDialogInfo->new;
	$about->SetName(__PACKAGE__);
	$about->SetDescription( <<"END_MESSAGE" );
Recording HTTP transfer using a sniffer.
END_MESSAGE

	# Show the About dialog
	Wx::AboutBox( $about );

	return;
}

sub sniff {
	my $inc = join "", map {"-I $_ "} @INC; #split /:/, $ENV{PERL5LIB};
	system qq(xterm -e "sudo perl $inc -MPadre::Plugin::HTTPRecordReplay::Sniff -e'sniff()'; sleep 10"&);
}

1;

# Copyright 2008-2009 The Padre development team as listed in Padre.pm.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.
