package Padre::Plugin::Debug::Breakpointspl;

use 5.008;
use strict;
use warnings;


use Padre::Wx::Role::View ();
use Padre::Plugin::Debug::FBP::BreakpointsPL;

our $VERSION = '0.01';
our @ISA     = qw{ Padre::Wx::Role::View Padre::Plugin::Debug::FBP::BreakpointsPL };


#######
# new
#######
sub new {
    my $class = shift;
	my $main  = shift;
	my $panel = $main->right;

    # Create the panel
    my $self  = $class->SUPER::new($panel);

    $main->aui->Update;

    return $self;
}

###############
# Make Padre::Wx::Role::View happy
###############

sub view_panel {
	my $self = shift;

	# This method describes which panel the tool lives in.
	# Returns the string 'right', 'left', or 'bottom'.

	return 'right';
}

sub view_label {
	my $self = shift;

	# The method returns the string that the notebook label should be filled
	# with. This should be internationalised properly. This method is called
	# once when the object is constructed, and again if the user triggers a
	# C<relocale> cascade to change their interface language.

	return Wx::gettext('Breakpoints');
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

sub view_icon {
	my $self = shift;

	# This method should return a valid Wx bitmap to be used as the icon for
	# a notebook page (displayed alongside C<view_label>).
	return;
}

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

1;

__END__

