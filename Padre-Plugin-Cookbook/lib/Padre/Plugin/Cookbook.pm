package Padre::Plugin::Cookbook;

use 5.010;
use strict;
use warnings;
use diagnostics;
use utf8;
use autodie;

# Version required
use version; our $VERSION = qv(0.13);
use parent qw(Padre::Plugin);

#######
# Define Padre Interfaces required
#######
sub padre_interfaces {
	return (

		# Default, required
		'Padre::Plugin' => 0.84,

		# used by MainFB by Padre::Plugin::FormBuilder
		'Padre::Wx::Role::Main' => 0.84,

		# used by MainFb by Padre::Plugin::FormBuilder
		'Wx::Dialog' => 0.00,
	);
}

#######
# Define Plugin Name required
#######
sub plugin_name {
	return 'Cookbook01';
}

#######
# Add Plugin to Padre Menu
#######
sub menu_plugins_simple {
	my $self = shift;
	return $self->plugin_name => [ 'Cookbook-01' => sub { $self->load_dialog_main; }, ];
}

#######
# Clean up dialog Main, Padre::Plugin,
# POD out of date as of v0.84
#######
sub plugin_disable {
	my $self = shift;
	$self->unload('Padre::Plugin::Cookbook::Main');        # child first
	$self->unload('Padre::Plugin::Cookbook::FBP::MainFB'); # parent second
	return 1;
}

########
# Composed Method,
# Load Main Dialog, only once
#######
sub load_dialog_main {
	my $self = shift;

	# Padre main window integration
	my $main = $self->main;

	# Clean up any previous existing dialog
	if ( $self->{dialog} ) {
		$self->{dialog}->Destroy;
		$self->{dialog} = undef;
	}

	# Create the new dialog
	require Padre::Plugin::Cookbook::Main;
	$self->{dialog} = Padre::Plugin::Cookbook::Main->new($main);
	$self->{dialog}->Show;

	return;
}

1;
__END__

=head1 NAME

Padre::Plugin::Cookbook

=head1 VERSION

This document describes Padre::Plugin::Cookbook version 0.13
  
=head1 DESCRIPTION

Cookbook 'Hello World'

Cookbook is just an example Padre::Plugin uing a WxDialog, showing minimal requirements.

=head1 SUBROUTINES/METHODS

=over 4

=item padre_interfaces ( )

Required method with minimum requirements

	sub padre_interfaces {
	return (
		# Default, required
		'Padre::Plugin'         => 0.84,
		# used by MainFB by Padre::Plugin::FormBuilder
		'Padre::Wx::Role::Main' => 0.84,
		# used by MainFb by Padre::Plugin::FormBuilder
		'Wx::Dialog'            => 0.00,
		);
	}

Called by Padre::Wx::Dialog::PluginManager

	my @needs = $plugin->padre_interfaces;

=item plugin_name ( )

Required method with minimum requirements

	sub plugin_name {
		return 'Cookbook01';
	}

Called by Padre::Wx::Dialog::PluginManager

	# Updating plug-in name in right pane
	$self->{label}->SetLabel( $plugin->plugin_name );


=item menu_plugins_simple ()

This is where you defined your plugin menu name, note hyphen for clarity.

	return $self->plugin_name =>
		[ 'Cookbook-01' => sub { $self->load_dialog_main; }, ];



=item plugin_disable ()

Required method with minimum requirements

    $self->unload('Padre::Plugin::Cookbook::Main');    # child first
    $self->unload('Padre::Plugin::Cookbook::FBP::MainFB');  # parent second


=item load_dialog_main ()

loads our dialog Main, only allows one instance!

    require Padre::Plugin::Cookbook::Main;
    $self->{dialog} = Padre::Plugin::Cookbook::Main->new($main);
    $self->{dialog}->Show;

=back


=head1 CONFIGURATION AND ENVIRONMENT
 
Padre::Plugin::Cookbook requires no configuration files or environment variables.


=head1 DEPENDENCIES

Padre::Plugin::Cookbook::Main, Padre::Plugin::Cookbook::FBP::MainFB,
Padre::Plugin, Padre::Wx::Role::Main, Wx::Dialog,

=head1 AUTHOR

bowtie

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2008-2011 The Padre development team as listed in Padre.pm.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

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
