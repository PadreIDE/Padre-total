package Padre::Plugin::Debug;

use 5.010;
use strict;
use warnings;
use Padre::Plugin ();

# Turn on $OUTPUT_AUTOFLUSH
$| = 1;
use diagnostics;
use utf8;

our $VERSION = '0.02';
our @ISA     = 'Padre::Plugin';

#######
# Define Padre Interfaces required
#######
sub padre_interfaces {
	return (

		# Default, required
		'Padre::Plugin' => '0.91',

		# used by Main, and by Padre::Plugin::FormBuilder
		'Padre::Wx'             => '0.91',
		'Padre::Wx::Main'       => '0.91',
		'Padre::Wx::Role::Main' => '0.91',
		'Padre::Logger'         => '0.91',
		'Padre::Current'        => '0.91',
		'Padre::Util'           => '0.91',
	);
}

#######
# Define Plugin Name required
#######
sub plugin_name {
	return Wx::gettext('Padre Debug... Beta');
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
			eval { $self->load_dialog_main( $_[0] ); };
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
	require Padre::Plugin::Debug::Main;
	$self->{dialog} = Padre::Plugin::Debug::Main->new($main);
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
	require Padre::Plugin::Debug::Main;
	Padre::Plugin::Debug::Main::unload_panel_debug();

	# Unload all our child classes
	$self->unload(
		qw{
			Padre::Plugin::Debug::Main
			Padre::Plugin::Debug::FBP::MainFB
			Padre::Plugin::Debug::DebugOutput
			Padre::Plugin::Debug::FBP::DebugOutput
			Padre::Plugin::Debug::Breakpoints
			Padre::Plugin::Debug::FBP::Breakpoints
			Padre::Plugin::Debug::Wx::Debugger
			Debug::Client
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
		$self->{dialog}->Hide;
		$self->{dialog}->Destroy;
		delete $self->{dialog};
	}

	return 1;
}

1;
