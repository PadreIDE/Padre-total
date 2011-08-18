package Padre::Plugin::Patch;

use 5.008;
use strict;
use warnings;
use Padre::Plugin ();

our $VERSION = '0.03';
our @ISA     = 'Padre::Plugin';

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
	Wx::gettext('Padre Patch... Beta');
}

#######
# Add Plugin to Padre Menu
#######
sub menu_plugins {
	my $self = shift;
	my $main = $self->main;

	# Create a manual menu item
	my $item = Wx::MenuItem->new( undef, -1, $self->plugin_name, );
	Wx::Event::EVT_MENU(
		$main, $item,
		sub {
			local $@;
			eval {
				$self->load_dialog_main($_[0]);
			};
		},
	);

	return $item;
}

########
# Composed Method,
# Load Recipe-01 Main Dialog, only once
#######
sub load_dialog_main {
	my $self = shift;
	my $main = shift;

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

1;
