package Padre::Plugin::Cookbook;

use 5.010001;
use strict;
use warnings;
use Padre::Plugin ();

our $VERSION = '0.140';
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
	);
}

#######
# Define Plugin Name required
#######
sub plugin_name {
	return 'Plugin Cookbook';
}

#######
# Add Plugin to Padre Menu
#######
sub menu_plugins_simple {
	my $self = shift;
	return $self->plugin_name => [
		'01 - Hello World' => sub {
			$self->load_dialog_recipe01_main;
		},
		'02 - Fun with widgets' => sub {
			$self->load_dialog_recipe02_main;
		},
		'03 - About dialogs' => sub {
			$self->load_dialog_recipe03_main;
		},
		'04 - ConfigDB RC1' => sub {
			$self->load_dialog_recipe04_main;
		},
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
#use Try::Tiny;
#use Carp;
#use Data::Printer;
#
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
#
#    return;
#}

1;

__END__

=head1 NAME

Padre::Plugin::Cookbook

=head1 VERSION

This document describes Padre::Plugin::Cookbook version 0.14
  
=head1 DESCRIPTION

Cookbook is just an example Padre::Plugin using a WxDialog, showing minimal requirements.

=head1 METHODS

=head2 padre_interfaces

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

=head2 plugin_name

Required method with minimum requirements

	sub plugin_name {
		return 'Plugin Cookbook';
	}

Called by Padre::Wx::Dialog::PluginManager

	# Updating plug-in name in right pane
	$self->{label}->SetLabel( $plugin->plugin_name );


=head2 menu_plugins_simple

This is where you defined your plugin menu name, note hyphen for clarity.

		return $self->plugin_name => [
		'01 - Hello World' => sub {
			$self->load_dialog_recipe01_main;
		},
		'02 - Fun with widgets' => sub {
			$self->load_dialog_recipe02_main;
		},
		'03 - About dialogs' => sub {
			$self->load_dialog_recipe03_main;
		},
		'04 - ConfigDB RC1' => sub {
			$self->load_dialog_recipe04_main;
		},
	];

=head2 plugin_disable

Required method with minimum requirements

    $self->unload('Padre::Plugin::Cookbook::Recipe01::Main');
    $self->unload('Padre::Plugin::Cookbook::Recipe01::FBP::MainFB');
    $self->unload('Padre::Plugin::Cookbook::Recipe02::Main');
    $self->unload('Padre::Plugin::Cookbook::Recipe02::FBP::MainFB');
    $self->unload('Padre::Plugin::Cookbook::Recipe03::Main');
    $self->unload('Padre::Plugin::Cookbook::Recipe03::FBP::MainFB');

=head2 load_dialog_recipe01_main

loads our dialog Main, only allows one instance!

    require Padre::Plugin::Cookbook::Recipe01::Main;
    $self->{dialog} = Padre::Plugin::Cookbook::Recipe01::Main->new($main);

=head2 load_dialog_recipe02_main

loads our dialog Main, only allows one instance!

    require Padre::Plugin::Cookbook::Recipe02::Main;
    $self->{dialog} = Padre::Plugin::Cookbook::Recipe02::Main->new($main);

=head2 load_dialog_recipe03_main

loads our dialog Main, only allows one instance!

    require Padre::Plugin::Cookbook::Recipe03::Main;
    $self->{dialog} = Padre::Plugin::Cookbook::Recipe03::Main->new($main);

=head2 load_dialog_recipe04_main

loads our dialog Main, only allows one instance!

    require Padre::Plugin::Cookbook::Recipe04::Main;
    $self->{dialog} = Padre::Plugin::Cookbook::Recipe04::Main->new($main);
    $self->{dialog}->Show;

=head1 AUTHOR

BOWTIE E<lt>kevin.dawson@btclick.comE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2008-2011 The Padre development team as listed in Padre.pm.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
