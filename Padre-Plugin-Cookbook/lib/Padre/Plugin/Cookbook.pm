package Padre::Plugin::Cookbook;

use 5.010001;
use strict;
use warnings;
use diagnostics;
use utf8;
use autodie;

# Avoids regex performance penalty
use English qw( -no_match_vars );

# Version required
use version; our $VERSION = qv(0.14);
use parent qw(Padre::Plugin);

# use TryCatch;
use Try::Tiny;
# use Data::Dumper;
use Data::Printer;
use Carp;

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
		# removed as advised by Sewi
		# 'Wx::Dialog' => 0.00,
	);
}

#######
# Define Plugin Name required
#######
sub plugin_name {
	return 'Cookbook';
}

#######
# Add Plugin to Padre Menu
#######
sub menu_plugins_simple {
	my $self = shift;
	return $self->plugin_name => [
		'Plug-ins - wxDialogs...' => [
			'Recipe-01 - Hello World' => sub { $self->load_dialog_recipe01_main(); },

			# 'Recipe-01 - Hello World' => sub { $self->load_dialog_recipexx_main('Recipe01'); },

			'Recipe-02 - Fun with widgets' => sub { $self->load_dialog_recipe02_main(); },

			# 'Recipe-02 - Fun with widgets' => sub { $self->load_dialog_recipexx_main('Recipe02'); },

			'Recipe-03 - inc About dialog' => sub { $self->load_dialog_recipe03_main(); },

			# 'Recipe-03 - out & About' => sub { $self->load_dialog_recipexx_main('Recipe03'); },

			'Recipe-04 - ConfigDB RC1' => sub { $self->load_dialog_recipe04_main(); },

			# 'Recipe-04 - ConfigDB RC1' => sub { $self->load_dialog_recipexx_main('Recipe04'); },
		],
	];
}

#######
# Clean up dialog Main, Padre::Plugin,
# POD out of date as of v0.84
#######
sub plugin_disable {
	my $self = shift;

	# Close the dialog if it is hanging around
	if ( $self->{dialog} ) {
		$self->{dialog}->Destroy;
		$self->{dialog} = undef;
	}

	# Unload all our child classes
	$self->unload('Padre::Plugin::Cookbook::Recipe01::Main');
	$self->unload('Padre::Plugin::Cookbook::Recipe01::FBP::MainFB');
	$self->unload('Padre::Plugin::Cookbook::Recipe02::Main');
	$self->unload('Padre::Plugin::Cookbook::Recipe02::FBP::MainFB');
	$self->unload('Padre::Plugin::Cookbook::Recipe03::Main');
	$self->unload('Padre::Plugin::Cookbook::Recipe03::FBP::MainFB');
	$self->unload('Padre::Plugin::Cookbook::Recipe03::About');
	$self->unload('Padre::Plugin::Cookbook::Recipe03::FBP::AboutFB');
	$self->unload('Padre::Plugin::Cookbook::Recipe04::Main');
	$self->unload('Padre::Plugin::Cookbook::Recipe04::FBP::MainFB');
	$self->unload('Padre::Plugin::Cookbook::Recipe04::About');
	$self->unload('Padre::Plugin::Cookbook::Recipe04::FBP::AboutFB');

	return 1;
}

########
# Composed Method,
# Load Recipe-01 Main Dialog, only once
#######
sub load_dialog_recipe01_main {
	my $self = shift;

	# Padre main window integration
	my $main = $self->main;

	# Clean up any previous existing dialog
	if ( $self->{dialog} ) {
		$self->{dialog}->Destroy;
		$self->{dialog} = undef;
	}

	# Create the new dialog
	require Padre::Plugin::Cookbook::Recipe01::Main;
	$self->{dialog} = Padre::Plugin::Cookbook::Recipe01::Main->new($main);
	$self->{dialog}->Show;

	return;
}

########
# Composed Method,
# Load Recipe-02 Main Dialog, only once
#######
sub load_dialog_recipe02_main {
	my $self = shift;

	# Padre main window integration
	my $main = $self->main;

	# Clean up any previous existing dialog
	if ( $self->{dialog} ) {
		$self->{dialog}->Destroy;
		$self->{dialog} = undef;
	}

	# Create the new dialog
	require Padre::Plugin::Cookbook::Recipe02::Main;
	$self->{dialog} = Padre::Plugin::Cookbook::Recipe02::Main->new($main);
	$self->{dialog}->Show;

	return;
}

########
# Composed Method,
# Load Recipe-03 Main Dialog, only once
#######
sub load_dialog_recipe03_main {
	my $self = shift;

	# Padre main window integration
	my $main = $self->main;

	# Clean up any previous existing dialog
	if ( $self->{dialog} ) {
		$self->{dialog}->Destroy;
		$self->{dialog} = undef;
	}

	# Create the new dialog
	require Padre::Plugin::Cookbook::Recipe03::Main;
	$self->{dialog} = Padre::Plugin::Cookbook::Recipe03::Main->new($main);
	$self->{dialog}->Show;

	return;
}

########
# Composed Method,
# Load Recipe-04 Main Dialog, only once
#######
sub load_dialog_recipe04_main {
	my $self = shift;

	# Padre main window integration
	my $main = $self->main;

	# Clean up any previous existing dialog
	if ( $self->{dialog} ) {
		$self->{dialog}->Destroy;
		$self->{dialog} = undef;
	}

	# Create the new dialog
	require Padre::Plugin::Cookbook::Recipe04::Main;
	$self->{dialog} = Padre::Plugin::Cookbook::Recipe04::Main->new($main);
	$self->{dialog}->Show;
	$self->{dialog}->set_up;

	return;
}

### Testing below
########
# Composed Method,
# Load Recipe-xx Main Dialog, only once
#######
#sub load_dialog_recipexx_main {
#    my ( $self, $recipe_num ) = @ARG;
#
# Padre main window integration
# my $main = $self->main;
#
# Clean up any previous existing dialog
# if ( $self->{dialog} ) {
# $self->{dialog}->Destroy;
# $self->{dialog} = undef;
# }
#
# try {
# "require" statement with library name as string
# require 'Padre/Plugin/Cookbook/' . $recipe_num . '/Main.pm';
# }
# catch {
# say '*** Require failed: ' . $recipe_num;
# p $recipe_num;
# carp($EVAL_ERROR);
# return;
# };
#
# load requested dialog main
# my $tmp_obj = 'Padre::Plugin::Cookbook::' . $recipe_num . '::Main';
# $self->{dialog} = $tmp_obj->new($main);
# $self->{dialog}->Show;
#
# try {
# $self->{dialog}->set_up;
# }
# catch {
# say '* info method ' . $recipe_num . '::set_up not found, ok';
# };

#    return;
#}

1;
__END__

=head1 NAME

Padre::Plugin::Cookbook

=head1 VERSION

This document describes Padre::Plugin::Cookbook version 0.14
  
=head1 DESCRIPTION

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
		);
	}

Called by Padre::Wx::Dialog::PluginManager

	my @needs = $plugin->padre_interfaces;

=item plugin_name ( )

Required method with minimum requirements

	sub plugin_name {
		return 'Cookbook';
	}

Called by Padre::Wx::Dialog::PluginManager

	# Updating plug-in name in right pane
	$self->{label}->SetLabel( $plugin->plugin_name );


=item menu_plugins_simple ()

This is where you defined your plugin menu name, note hyphen for clarity.

	return $self->plugin_name => [
		'Plug-ins - wxDialogs...' => [
			'Recipe-01 - Hello World' => sub { $self->load_dialog_recipe01_main; },
			'Recipe-02 - Fun with widgets' => sub { $self->load_dialog_recipe02_main; },
			'Recipe-03 - inc About dialog' => sub { $self->load_dialog_recipe03_main; },
		],
	];

=item plugin_disable ()

Required method with minimum requirements

    $self->unload('Padre::Plugin::Cookbook::Recipe01::Main');
    $self->unload('Padre::Plugin::Cookbook::Recipe01::FBP::MainFB');
    $self->unload('Padre::Plugin::Cookbook::Recipe02::Main');
    $self->unload('Padre::Plugin::Cookbook::Recipe02::FBP::MainFB');
    $self->unload('Padre::Plugin::Cookbook::Recipe03::Main');
    $self->unload('Padre::Plugin::Cookbook::Recipe03::FBP::MainFB');

=item load_dialog_recipe01_main ()

loads our dialog Main, only allows one instance!

    require Padre::Plugin::Cookbook::Recipe01::Main;
    $self->{dialog} = Padre::Plugin::Cookbook::Recipe01::Main->new($main);


=item load_dialog_recipe02_main ()

loads our dialog Main, only allows one instance!

    require Padre::Plugin::Cookbook::Recipe02::Main;
    $self->{dialog} = Padre::Plugin::Cookbook::Recipe02::Main->new($main);


=item load_dialog_recipe03_main ()

loads our dialog Main, only allows one instance!

    require Padre::Plugin::Cookbook::Recipe03::Main;
    $self->{dialog} = Padre::Plugin::Cookbook::Recipe03::Main->new($main);

  
=item load_dialog_recipe04_main ()

loads our dialog Main, only allows one instance!

    require Padre::Plugin::Cookbook::Recipe04::Main;
    $self->{dialog} = Padre::Plugin::Cookbook::Recipe04::Main->new($main);
    $self->{dialog}->Show;

    
=back

=head1 CONFIGURATION AND ENVIRONMENT
 
Padre::Plugin::Cookbook requires no configuration files or environment variables.


=head1 DEPENDENCIES

Padre::Plugin::Cookbook::Recipe01::Main, Padre::Plugin::Cookbook::Recipe01::FBP::MainFB, 
Padre::Plugin::Cookbook::Recipe02::Main, Padre::Plugin::Cookbook::Recipe02::FBP::MainFB,
Padre::Plugin::Cookbook::Recipe03::Main, Padre::Plugin::Cookbook::Recipe03::FBP::MainFB,
Padre::Plugin::Cookbook::Recipe03::About, Padre::Plugin::Cookbook::Recipe03::FBP::AboutFB,
Padre::Plugin, Padre::Wx::Role::Main, Wx::Dialog,

=head1 AUTHOR

BOWTIE E<lt>kevin.dawson@btclick.comE<gt>

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
