package Padre::Plugin::Debug::DebugOutput;

use 5.010;
use strict;
use warnings;

use Padre::Wx::Role::View;
use Padre::Plugin::Debug::FBP::DebugOutput ();
use Data::Printer { caller_info => 1, colored => 1, };
our $VERSION = '0.01';

our @ISA     = qw{
	Padre::Wx::Role::View
	Padre::Plugin::Debug::FBP::DebugOutput
};


#######
# new
#######
# sub new { # todo use a better object constructor
	# my $class = shift; # What class are we constructing?
	# my $self  = {};    # Allocate new memory
	# bless $self, $class; # Mark it of the right type
	# $self->_init(@_);    # Call _init with remaining args
	# return $self;
# } #new

# # sub _init {
	# my ( $self, @args ) = @_;

# # 	# $self->{client} = undef;
	# # $self->{file}   = undef;
	# # $self->{save}   = {};

# # 	return $self;
# } #_init
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

# sub enable {
	# my $self     = shift;
	# # TRACE( "Enable Chat" ) if DEBUG;

# # 	# Add ourself to the gui;
	# my $main     = Padre->ide->wx->main;
	# my $bottom   = $self->bottom;
	# my $position = $bottom->GetPageCount;
	# # $self->update_userlist;
	# $bottom->show($self);

# # 	# $self->textinput->SetFocus;
	# $main->aui->Update;

# # 	$self->{enabled} = 1;
# }

# sub disable {
	# my $self = shift;
	# # TRACE( 'Disable Chat' ) if DEBUG;
	# # $self->universe->send( {type=>'leave', service=>'chat' } );
	# my $main = Padre->ide->wx->main;
	# my $bottom= $main->bottom;
	# my $position = $bottom->GetPageIndex($self);
	# $self->Hide;

# # 	# TRACE( "disable - $bottom" ) if DEBUG;
	# $bottom->RemovePage($position);
	# $main->aui->Update;
	# #$self->Destroy;
# }

sub debug_out {
	my $self = shift;
	my $out_text = shift;

	$self->{output}->AppendText($out_text . "\n");
	return;
}


1;

__END__
