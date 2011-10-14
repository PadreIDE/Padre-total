package Padre::Plugin::Debug::Breakpoints;

use 5.010;
use strict;
use warnings;

use Padre::Wx::Role::Main   ();
use Padre::Wx::Role::View ();
use Padre::Wx               ();
use Padre::Plugin::Debug::FBP::Breakpoints;

our $VERSION = '0.01';
our @ISA     = qw{ Padre::Wx::Role::View Padre::Wx::Role::Main Padre::Plugin::Debug::FBP::Breakpoints };


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
    
    $self->set_up();

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

###############################



#######
# Method set_up
#######
sub set_up {
	my $self = shift;

	$self->{debug_visable}       = 0;
	$self->{breakpoints_visable} = 0;

	# Setup the debug button icons

	# $self->{step_in}->SetBitmapLabel( Padre::Wx::Icon::find('stock/code/stock_macro-stop-after-command') );
	# $self->{step_in}->Disable;

# # 	$self->{step_over}->SetBitmapLabel( Padre::Wx::Icon::find('stock/code/stock_macro-stop-after-procedure') );
	# $self->{step_over}->Disable;

# # 	$self->{step_out}->SetBitmapLabel( Padre::Wx::Icon::find('stock/code/stock_macro-jump-back') );
	# $self->{step_out}->Disable;

# # 	$self->{run_till}->SetBitmapLabel( Padre::Wx::Icon::find('stock/code/stock_tools-macro') );
	# $self->{run_till}->Disable;
	
	$self->{refresh}->SetBitmapLabel( Padre::Wx::Icon::find('actions/view-refresh') );
	$self->{refresh}->Enable;
	
	$self->{set_breakpoints}->SetBitmapLabel( Padre::Wx::Icon::find('stock/code/stock_macro-insert-breakpoint') );
	$self->{set_breakpoints}->Enable;

	# $self->{display_value}->SetBitmapLabel( Padre::Wx::Icon::find('stock/code/stock_macro-watch-variable') );
	# $self->{display_value}->Disable;

# # 	$self->{quit_debugger}->SetBitmapLabel( Padre::Wx::Icon::find('actions/stop') );
	# $self->{quit_debugger}->Disable;

	$self->_setup_db();

	return;
}





sub on_refresh_click {
	my $self = shift;

	say 'on_refresh_click';

	return;
}


# sub set_breakpoints_clicked {
	# $_[0]->main->error('Handler method set_breakpoints_clicked for event set_breakpoints.OnButtonClick not implemented');
# }

sub on_show_project_click {
	my $self = shift;

	say 'on_show_project_click';

	return;
}



#######
# event handler breakpoint_clicked
#######
sub set_breakpoints_clicked {
	my $self    = shift;
	my $main    = $self->main;
	my $current = $main->current;

	# $self->running or return;
	my $editor = Padre::Current->editor;
	$self->{bp_file} = $editor->{Document}->filename;
	$self->{bp_line} = $editor->GetCurrentLine + 1;

	# p $current->project->root;
	# dereferance array and test for contents
	if ($#{ $self->{debug_breakpoints}
				->select("WHERE filename = \"$self->{bp_file}\" AND line_number = \"$self->{bp_line}\"")
		} >= 0
		)
	{
		say 'delete me';
		$editor->MarkerDelete( $self->{bp_line} - 1, Padre::Constant::MARKER_BREAKPOINT() );
		$self->_delete_bp_db();

	} else {
		say 'create me';
		$self->{bp_active} = 1;
		$editor->MarkerAdd( $self->{bp_line} - 1, Padre::Constant::MARKER_BREAKPOINT() );
		$self->_add_bp_db();
	}

	return;
}


########
# Debug Breakpoint DB
########

#######
# internal method _setup_db connector
#######
sub _setup_db {
	my $self = shift;

	# set padre db relation
	$self->{debug_breakpoints} = ('Padre::DB::DebugBreakpoints');

	# p $self->{debug_breakpoints};
	# p $self->{debug_breakpoints}->table_info;
	# p $self->{debug_breakpoints}->select;
	return;
}

#######
# internal method _add_bp_db
#######
sub _add_bp_db {
	my $self = shift;

	$self->{debug_breakpoints}->create(
		filename    => $self->{bp_file},
		line_number => $self->{bp_line},
		active      => $self->{bp_active},
		last_used   => time(),
	);

	# p $self->{debug_breakpoints}->select;
	return;
}

#######
# internal method _delete_bp_db
#######
sub _delete_bp_db {
	my $self = shift;

	$self->{debug_breakpoints}->delete("WHERE filename = \"$self->{bp_file}\" AND line_number = \"$self->{bp_line}\"");

	# p $self->{debug_breakpoints}->select;
	return;
}

1;

__END__

