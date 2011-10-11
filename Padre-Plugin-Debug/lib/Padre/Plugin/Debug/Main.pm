package Padre::Plugin::Debug::Main;

use 5.010;
use strict;
use warnings;

use Padre::Wx                         ();
use Padre::Plugin::Debug::FBP::MainFB ();
# use Padre::Current                    ();
# use Padre::Util                       ();
# use Padre::Logger qw(TRACE DEBUG);

use Data::Printer { caller_info => 1, colored => 1, };
our $VERSION = '0.04';
our @ISA     = 'Padre::Plugin::Debug::FBP::MainFB';

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
	
	$self->{debug_bottom} = 0;

	return;
}

########
# Event Handler on_debug_bottom_clicked
########
sub on_debug_bottom_clicked {
	my $self = shift;
	
	if ( $self->{debug_visable} eq 1 ) {
		#todo turn off
		$self->unload_panel_debug();
	}
	else {
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
	
	if ( $self->{breakpoints_visable} eq 1 ) {
		#todo turn off
		$self->unload_panel_breakpoints();
	}
	else {
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

sub breakpoint_clicked {
	my $self = shift;
	say 'breakpoint_clicked: '.$self->bp_line_number->GetValue();
	return;
}

1;

__END__
