package Padre::Plugin::Debug;

use 5.010;
use strict;
use warnings;
use Padre::Plugin ();

# Turn on $OUTPUT_AUTOFLUSH
$| = 1;
use diagnostics;
use utf8;

our $VERSION = '0.13_05';
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
		# 'Wx::Dialog'            => '0.91',
		# 'Wx::Panel'             => '0.91',
		'Padre::Wx::Main'       => '0.91',
		'Padre::Wx::Role::Main' => '0.91',
		'Padre::Wx::Role::View' => '0.91',
		'Padre::Logger'         => '0.91',
		'Padre::Current'        => '0.91',
		'Padre::Util'           => '0.91',
	);
}

#######
# Define Plugin Name required
#######
sub plugin_name {
	return Wx::gettext('Padre Debug... RC1');
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
			Padre::Plugin::Debug::Panel::DebugOutput
			Padre::Plugin::Debug::FBP::DebugOutput
			Padre::Plugin::Debug::Panel::Breakpoints
			Padre::Plugin::Debug::FBP::Breakpoints
			Padre::Plugin::Debug::Panel::DebugVariable
			Padre::Plugin::Debug::FBP::DebugVariable
			Padre::Plugin::Debug::Panel::Debugger
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

#########
# We need plugin_enable
# as we have an external dependency
#########
sub plugin_enable {

	# Tests for external file in Path
	require Debug::Client;

	if ( $Debug::Client::VERSION eq '0.13_05' ) {
		return 1;
	} else {
		return 0;
	}
}

1;

=head1 P-P-Debug 

Is a new Panel based interface to Perl -d

terminology from perldebug

Panel's inc:

 Debugger, right
 Breakpoints, left
 Debug-Output, bottom (only when debugger is running)

The debug-simulator is only because we are running as a plugin_enable
suggest you only use the two check marks at top.

You can use the Padre tool bar simulator, but there is no auto update of icons 
between sim-bar and panels though.

See Padre::Plugin::Debug::Main for more POD

Requires Debug::Client 0.13_05

Author => bowtie

And all becasus Alias said RTFM :)

=cut
