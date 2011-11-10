package Padre::Plugin::Debug::Panel::DebugOutput;

use 5.010;
use strict;
use warnings;

# Turn on $OUTPUT_AUTOFLUSH
$| = 1;
use diagnostics;
use utf8;

use Padre::Wx::Role::View;
use Padre::Plugin::Debug::FBP::DebugOutput ();
use Data::Printer { caller_info => 1, colored => 1, };
our $VERSION = '0.13';

our @ISA = qw{
	Padre::Wx::Role::View
	Padre::Plugin::Debug::FBP::DebugOutput
};

use constant {
	RED        => Wx::Colour->new('red'),
	DARK_GREEN => Wx::Colour->new( 0x00, 0x90, 0x00 ),
	BLUE       => Wx::Colour->new('blue'),
	GRAY       => Wx::Colour->new('gray'),
	BLACK      => Wx::Colour->new('black'),
};

#######
# new
#######
sub new {
	my $class = shift;
	my $main  = shift;
	my $panel = shift || $main->bottom;

	# 	# Create the panel
	my $self = $class->SUPER::new($panel);

	return $self;
}

###############
# Make Padre::Wx::Role::View happy
###############

sub view_panel {
	my $self = shift;

	# This method describes which panel the tool lives in.
	# Returns the string 'right', 'left', or 'bottom'.

	return 'bottom';
}

sub view_label {
	my $self = shift;

	# The method returns the string that the notebook label should be filled
	# with. This should be internationalised properly. This method is called
	# once when the object is constructed, and again if the user triggers a
	# C<relocale> cascade to change their interface language.

	return Wx::gettext('Debug Output');
}


sub view_close {
	my $self = shift;

	# This method is called on the object by the event handler for the "X"
	# control on the notebook label, if it has one.

	# The method should generally initiate whatever is needed to close the
	# tool via the highest level API. Note that while we aren't calling the
	# equivalent menu handler directly, we are calling the high-level method
	# on the main window that the menu itself calls.
	return;
}

#
#  sub view_icon {
#  	my $self = shift;
#
# 	# This method should return a valid Wx bitmap to be used as the icon for
# 	# a notebook page (displayed alongside C<view_label>).
# 	return;
# }
#
sub view_start {
	my $self = shift;

	# Called immediately after the view has been displayed, to allow the view
	# to kick off any timers or do additional post-creation setup.
	return;
}

sub view_stop {
	my $self = shift;

	# Called immediately before the view is hidden, to allow the view to cancel
	# any timers, cancel tasks or do pre-destruction teardown.
	return;
}

sub gettext_label {
	Wx::gettext('Debug Output');
}
###############
# Make Padre::Wx::Role::View happy end
###############

sub debug_output {
	my $self   = shift;
	my $output = shift;

	#TODO change to DARK_RED
	$self->{output}->SetForegroundColour(RED);
	$self->{output}->ChangeValue($output);

	# $self->{output}->AppendText($out_text . "\n");
	return;
}

sub debug_status {
	my $self = shift;
	my $status =shift;
	$self->{status}->SetLabel($status);
	return; 
}


1;

__END__
