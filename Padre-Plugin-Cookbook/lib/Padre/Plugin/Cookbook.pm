package Padre::Plugin::Cookbook;

use 5.010001;
use strict;
use warnings;

# use Padre::Plugin ();

our $VERSION = '0.140';
use parent qw(Padre::Plugin);

#######
# Define Padre Interfaces required
#######
sub padre_interfaces {
	return (

		# Default, required
		'Padre::Plugin' => '0.84',

		# used by Main, About and by Padre::Plugin::FormBuilder
		'Padre::Wx'             => 0.84,
		'Padre::Wx::Main'       => '0.86',
		'Padre::Wx::Role::Main' => 0.84,
		'Padre::Logger'         => '0.84',
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

# sub plugin_icon {
# my $class = shift;
# my $share = $class->plugin_directory_share or return;
# my $file  = File::Spec->catfile( $share, 'icons', '16x16', 'cookbook.png' );
# return unless -f $file;
# return unless -r $file;
# return Wx::Bitmap->new( $file, Wx::wxBITMAP_TYPE_PNG );
# }

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
	$self->unload(
		qw{
			Padre::Plugin::Cookbook::Recipe01::Main
			Padre::Plugin::Cookbook::Recipe01::FBP::MainFB
			Padre::Plugin::Cookbook::Recipe02::Main
			Padre::Plugin::Cookbook::Recipe02::FBP::MainFB
			Padre::Plugin::Cookbook::Recipe03::Main
			Padre::Plugin::Cookbook::Recipe03::FBP::MainFB
			Padre::Plugin::Cookbook::Recipe03::About
			Padre::Plugin::Cookbook::Recipe03::FBP::AboutFB
			Padre::Plugin::Cookbook::Recipe04::Main
			Padre::Plugin::Cookbook::Recipe04::FBP::MainFB
			Padre::Plugin::Cookbook::Recipe04::About
			Padre::Plugin::Cookbook::Recipe04::FBP::AboutFB
			}
	);

	$self->SUPER::plugin_disable(@_);

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

1;

__END__

=head1 NAME

Padre::Plugin::Cookbook

Cookbook contains recipes to assist you in makeing your own Padre::Plugins
You will find more info in the companion L<wiki|http://padre.perlide.org/trac/wiki/PadrePluginDialog/> pages.

=head1 VERSION

This document describes Padre::Plugin::Cookbook version 0.14
  
=head1 DESCRIPTION

Cookbook is just an example Padre::Plugin using a WxDialog, showing minimal requirements. It consists of a series of Recipes.

=over

=item Recipe 01, Hello World what else could it be.

=item Recipe 02, Fun with widgets and a Dialog (method modifiers and event handlers).

=item Recipe 03, Every Plug-in needs an About Dialogue or Multiple Dialogues.

=item Recipe 04, ListCtrl or ConfigDB.

=back

=head1 METHODS

=head2 padre_interfaces

Required method with minimum requirements

	sub padre_interfaces {
	return (
		# Default, required
		'Padre::Plugin'         => 0.84,
		
        # used by Main, About and by Padre::Plugin::FormBuilder
        'Padre::Wx' => 0.84,
        'Padre::Wx::Main' => '0.86',
        'Padre::Wx::Role::Main' => 0.84,
        'Padre::Logger' => '0.84',
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
	$self->unload('Padre::Plugin::Cookbook::Recipe03::About');
	$self->unload('Padre::Plugin::Cookbook::Recipe03::FBP::AboutFB');
	$self->unload('Padre::Plugin::Cookbook::Recipe04::Main');
	$self->unload('Padre::Plugin::Cookbook::Recipe04::FBP::MainFB');
	$self->unload('Padre::Plugin::Cookbook::Recipe04::About');
	$self->unload('Padre::Plugin::Cookbook::Recipe04::FBP::AboutFB');
	
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

=head1 BUGS AND LIMITATIONS 

=over

=item No bugs have been reported.

=back

=head1 DEPENDENCIES

Padre::Plugin, 
Padre::Plugin::Cookbook, 
Padre::Plugin::Cookbook::Recipe01::FBP::Main, Padre::Plugin::Cookbook::Recipe01::FBP::MainFB, 
Padre::Plugin::Cookbook::Recipe02::FBP::Main, Padre::Plugin::Cookbook::Recipe02::FBP::MainFB, 
Padre::Plugin::Cookbook::Recipe03::FBP::Main, Padre::Plugin::Cookbook::Recipe03::FBP::MainFB, 
Padre::Plugin::Cookbook::Recipe03::About, Padre::Plugin::Cookbook::Recipe03::FBP::AboutFB, 
Padre::Plugin::Cookbook::Recipe04::FBP::Main, Padre::Plugin::Cookbook::Recipe04::FBP::MainFB, 
Padre::Plugin::Cookbook::Recipe04::About, Padre::Plugin::Cookbook::Recipe04::FBP::AboutFB, 
Moose, namespace::autoclean, Data::Printer

=head1 AUTHOR

BOWTIE E<lt>kevin.dawson@btclick.comE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2008-2011 The Padre development team as listed in Padre.pm.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
