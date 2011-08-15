package Padre::Plugin::Patch;

use 5.010;
use warnings;
use strict;

use utf8;
use autodie;

our $VERSION = '0.02';
use English qw( -no_match_vars );
use Data::Printer { caller_info => 1 };

use Padre::Wx::Main       ();
use parent qw(Padre::Plugin);


#######
# Define Padre Interfaces required
#######
sub padre_interfaces {
	return (

		# Default, required
		'Padre::Plugin' => '0.89',

		# used by Main, and by Padre::Plugin::FormBuilder
		'Padre::Wx'             => '0.89',
		'Padre::Wx::Main'       => '0.89',
		'Padre::Wx::Role::Main' => '0.89',
		'Padre::Logger'         => '0.89',
	);
}

#######
# Define Plugin Name required
#######
sub plugin_name {
	return Wx::gettext('Padre Patch... Alpha');
}

#######
# Add Plugin to Padre Menu
#######
sub menu_plugins {
	my $self = shift;
	my $main = $self->main;

	# 	# Create a manual menu item
	my $item = Wx::MenuItem->new( undef, -1, $self->plugin_name, );
	Wx::Event::EVT_MENU(
		$main, $item,
		sub {
			local $@;
			eval { $self->load_dialog_main($main); };
		},
	);

	return $item;
}

########
# Composed Method,
# Load Recipe-01 Main Dialog, only once
#######
sub load_dialog_main {
	my ( $self, $main ) = @ARG;

	# Clean up any previous existing dialog
	$self->clean_dialog;

	# Create the new dialog
	require Padre::Plugin::Patch::Main;
	$self->{dialog} = Padre::Plugin::Patch::Main->new($main);
	$self->{dialog}->Show;

	return;
}

#######
# Clean up dialog Main, Padre::Plugin,
# POD out of date as of v0.84
#######
sub plugin_disable {
	my $self = shift;

	# Close the dialog if it is hanging around
	$self->clean_dialog;

	# Unload all our child classes
	$self->unload(
		qw{
			Padre::Plugin::Patch::Main
			Padre::Plugin::Patch::FBP::MainFB
			}
	);

	$self->SUPER::plugin_disable(@_);

	return 1;
}

########
# Composed Method clean_dialog
########
sub clean_dialog {
	my $self = shift;

	# Close the main dialog if it is hanging around
	if ( $self->{dialog} ) {
		$self->{dialog}->Destroy;
		delete $self->{dialog};
	}

	return 1;
}

1; # Magic true value required at end of module

__END__

=head1 NAME

Padre::Plugin::Patch - [One line description of module's purpose here]


=head1 VERSION

This document describes Padre::Plugin::Patch version 0.02


=head1 SYNOPSIS

    use Padre::Plugin::Patch;

=for author to fill in:
    Brief code example(s) here showing commonest usage(s).
    This section will be as far as many users bother reading
    so make it as educational and exeplary as possible.
  
  
=head1 DESCRIPTION

=for author to fill in:
    Write a full description of the module and its features here.
    Use subsections (=head2, =head3) as appropriate.


=head1 INTERFACE 

=for author to fill in:
    Write a separate section listing the public components of the modules
    interface. These normally consist of either subroutines that may be
    exported, or methods that may be called on objects belonging to the
    classes provided by the module.


=head1 DIAGNOSTICS

perl dev -a -t Padre::Plugin::Patch::Main


=head1 CONFIGURATION AND ENVIRONMENT
  
Padre::Plugin::Patch requires no configuration files or environment variables.


=head1 DEPENDENCIES

Padre::Plugin Padre::Plugin::Patch::Main, 
Padre::Plugin::Patch::FBP::MainFB, Text::Diff, Text::Patch,
Data::Printer


=head1 INCOMPATIBILITIES

None reported.


=head1 BUGS AND LIMITATIONS

Lots, but hay it's Alpha,


=head1 AUTHOR

BOWTIE  C<< <kevin.dawson@btclick.com> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2011, bowtie C<< <kevin.dawson@btclick.com> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
