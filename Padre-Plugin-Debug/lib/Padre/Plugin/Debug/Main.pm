package Padre::Plugin::Debug::Main;

use 5.010;
use strict;
use warnings;

# Turn on $OUTPUT_AUTOFLUSH
$| = 1;
use diagnostics;

use Padre::Wx                         ();
use Padre::Plugin::Debug::FBP::MainFB ();

# use Padre::Current                    ();
# use Padre::Util                       ();
# use Padre::Logger qw(TRACE DEBUG);

use Data::Printer { caller_info => 1, colored => 1, };
our $VERSION = '0.04';
use parent qw( Padre::Plugin::Debug::FBP::MainFB );

#######
# new
#######
sub new {
	my $class = shift;
	my $self  = $class->SUPER::new(@_);

	$self->CenterOnParent;
	$self->{action_request} = 'Patch';
	$self->{selection}      = 0;
	$self->set_up;
	return $self;
}

#######
# Method set_up
#######
sub set_up {
	my $self = shift;

	$self->{debug_visable}       = 0;
	$self->{breakpoints_visable} = 0;

	return;
}

########
# Event Handler on_debug_bottom_clicked
########
sub on_debug_bottom_clicked {
	my $self = shift;

	if ( $self->{debug_visable} == 1 ) {

		#todo turn off
		$self->unload_panel_debug();
	} else {

		#todo turn on
		$self->load_panel_debug();
	}

	return;
}

########
# Event Handler on_breakpoints_clicked
########
sub on_breakpoints_clicked {
	my $self = shift;
	my $main = $self->main;

	if ( $self->{breakpoints_visable} == 1 ) {

		#todo turn off
		$self->unload_panel_breakpoints();
	} else {

		#todo turn on
		$self->load_panel_breakpoints();
	}

	return;
}

########
# Composed Method,
# Load Panel Debug Bottom, only once
#######
sub load_panel_debug {
	my $self = shift;
	my $main = $self->main;

	# Close the dialog if it is hanging around
	# $self->clean_dialog;

	# Create the new about
	require Padre::Plugin::Debug::Bottom;
	$self->{panel_debug_bottom} = Padre::Plugin::Debug::Bottom->new($main);

	$self->{panel_debug_bottom}->Show;

	$main->aui->Update;

	$self->{debug_visable} = 1;

	return;
}

########
# Composed Method,
# Unload Panel Debug Bottom, only once
#######
sub unload_panel_debug {
	my $self = shift;

	# Close the main dialog if it is hanging around
	if ( $self->{panel_debug_bottom} ) {
		$self->{panel_debug_bottom}->Destroy;
		delete $self->{panel_debug_bottom};
	}

	$self->{debug_visable} = 0;

	return 1;
}

########
# Composed Method,
# Load Panel Breakpoints, only once
#######
sub load_panel_breakpoints {
	my $self = shift;
	my $main = $self->main;

	require Padre::Plugin::Debug::Breakpointspl;
	$self->{panel_breakpoints} = Padre::Plugin::Debug::Breakpointspl->new($main);

	$self->{panel_breakpoints}->Show;

	$main->aui->Update;

	$self->{breakpoints_visable} = 1;

	return;
}

########
# Composed Method,
# Unload Panel Breakpoints, only once
#######
sub unload_panel_breakpoints {
	my $self = shift;

	# Close the main dialog if it is hanging around
	if ( $self->{panel_breakpoints} ) {
		$self->{panel_breakpoints}->Destroy;
		delete $self->{panel_breakpoints};
	}

	$self->{breakpoints_visable} = 0;

	return 1;
}

#######
# Clean up our Classes, Padre::Plugin, POD out of date as of v0.84
#######
sub plugin_disable {
	my $self = shift;

	# Close the dialog if it is hanging around
	$self->unload_panel_debug;

	# Unload all our child classes
	$self->unload(
		qw{
			Padre::Plugin::Debug::Bottom
			Padre::Plugin::Debug::FBP::DebugPL
			}
	);

	$self->SUPER::plugin_disable(@_);
	return 1;
}

#######
# event handler breakpoint_clicked
#######
sub breakpoint_clicked {
	my $self = shift;
	say 'breakpoint_clicked: ' . $self->bp_line_number->GetValue();
	$self->add_bp_marker( $self->bp_line_number->GetValue() );
	return;
}

########
# composed method add_bp_marker
########
sub add_bp_marker {
	my $self           = shift;
	my $bp_line_number = shift;

	my $main = $self->main;

	# $self->running or return;

	my $editor = Padre::Current->editor;
	my $file   = $editor->{Document}->filename;
	p $file;

	# my $row    = $editor->GetCurrentLine + 1;
	my $row = $bp_line_number;

	# TODO ask for a condition
	# TODO allow setting breakpoints even before the script and the debugger runs
	# (by saving it in the debugger configuration file?)

	# if ( not $self->{client}->set_breakpoint( $file, $row ) ) {
	# $self->error( sprintf( Wx::gettext("Could not set breakpoint on file '%s' row '%s'"), $file, $row ) );
	# return;
	# }

	$editor->MarkerAdd( $row - 1, Padre::Constant::MARKER_BREAKPOINT );

	# TODO: This should be the condition I guess
	
	my %bp = ( filename => $file, line_number => $bp_line_number, active => 1, );
	p %bp;
	

	return;
}




1;

__END__
