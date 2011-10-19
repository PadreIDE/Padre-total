package Padre::Plugin::Debug::Breakpoints;

use 5.010;
use strict;
use warnings;

# use Padre::Wx::Role::Main ();
use Padre::Wx::Role::View ();
use Padre::Wx             ();
use Padre::Plugin::Debug::FBP::Breakpoints;
use English qw( -no_match_vars ); # Avoids regex performance penalty

our $VERSION = '0.01';
our @ISA     = qw{ Padre::Wx::Role::View  Padre::Plugin::Debug::FBP::Breakpoints };
use Data::Printer { caller_info => 1, colored => 1, };

#######
# new
#######
sub new {
	my $class = shift;
	my $main  = shift;
	my $panel = shift || $main->left;

	# Create the panel
	my $self = $class->SUPER::new($panel);

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

#
# sub view_icon {
# 	my $self = shift;
#
#  	# This method should return a valid Wx bitmap to be used as the icon for
#	# a notebook page (displayed alongside C<view_label>).
#	return;
#}
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
	Wx::gettext('BreakPoints');
}
###############
# Make Padre::Wx::Role::View happy end
###############


#######
# Method set_up
#######
sub set_up {
	my $self = shift;

	$self->{debug_visable}       = 0;
	$self->{breakpoints_visable} = 0;

	# Setup the debug button icons
	$self->{refresh}->SetBitmapLabel( Padre::Wx::Icon::find('actions/view-refresh') );
	$self->{refresh}->Enable;

	$self->{set_breakpoints}->SetBitmapLabel( Padre::Wx::Icon::find('stock/code/stock_macro-insert-breakpoint') );
	$self->{set_breakpoints}->Enable;

	# Update the checkboxes with their corresponding values in the
	# configuration
	$self->{show_project}->SetValue(0);
	$self->{show_project} = 0;

	$self->_setup_db();

	# Setup columns
	my @column_headers = qw( Line_No File_Name Active );
	my $index          = 0;
	for my $column_header (@column_headers) {
		$self->{list}->InsertColumn( $index++, Wx::gettext($column_header) );
	}

	# Tidy the list
	Padre::Util::tidy_list( $self->{list} );

	$self->on_refresh_click();

	return;
}

#######
# event handler on_refresh_click
#######
sub on_refresh_click {
	my $self    = shift;
	my $main    = $self->main;
	my $current = $main->current;

	$self->{project_dir}  = $current->document->project_dir;
	$self->{current_file} = $current->document->filename;

	# say 'on_refresh_click';
	$self->_update_list();

	return;
}

#######
# event handler on_show_project_click
#######
sub on_show_project_click {
	my ( $self, $event ) = @_;

	if ( $event->IsChecked ) {
		$self->{show_project} = 1;

		# say 'on_show_project_click yes';
		# say $self->{show_project};
	} else {
		$self->{show_project} = 0;

		# say 'on_show_project_click no';
		# say $self->{show_project};
	}

	$self->on_refresh_click();

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

		# say 'delete me';
		$editor->MarkerDelete( $self->{bp_line} - 1, Padre::Constant::MARKER_BREAKPOINT() );
		$self->_delete_bp_db();

	} else {

		# say 'create me';
		$self->{bp_active} = 1;
		$editor->MarkerAdd( $self->{bp_line} - 1, Padre::Constant::MARKER_BREAKPOINT() );
		$self->_add_bp_db();
	}
	$self->on_refresh_click();
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

sub test {
	my $self = shift;
	$self->_update_list();
	return;
}

#######
# Composed Method,
# display any relation db
#######
sub _update_list {
	my $self = shift;

	my $item = Wx::ListItem->new;

	# clear ListCtrl items
	$self->{list}->DeleteAllItems;

	my $editor = Padre::Current->editor;

	# eval { $self->{debug_breakpoints}->select; };
	# if ($EVAL_ERROR) {
	# say "Oops $self->config_db is damaged";
	# carp($EVAL_ERROR);
	# } else {
		
	my $sql_select = 'ORDER BY filename ASC, line_number ASC';
	my @tuples = $self->{debug_breakpoints}->select($sql_select);

	# $item->SetId($idx);
	# $self->{list}->InsertItem($item);
	# $self->{list}->SetItemData( $index, 0 );

	my $index = 0;

	for ( 0 .. $#tuples ) {

		if ( $tuples[$_][1] =~ m/^ $self->{project_dir} /sxm ) {
			if ( $self->{show_project} == 0 && $tuples[$_][1] =~ m/^$self->{current_file}/ ) {
				$item->SetId($index);
				$self->{list}->InsertItem($item);
				$self->{list}->SetItem( $index, 0, ( $tuples[$_][2] ) );
				$tuples[$_][1] =~ s/^ $self->{project_dir} //sxm;
				$self->{list}->SetItem( $index,   1, ( $tuples[$_][1] ) );
				$self->{list}->SetItem( $index++, 2, ( $tuples[$_][3] ) );
				$editor->MarkerAdd( $tuples[$_][2] - 1, Padre::Constant::MARKER_BREAKPOINT() );

			} elsif ( $self->{show_project} == 1 ) {
				$item->SetId($index);
				$self->{list}->InsertItem($item);
				$self->{list}->SetItem( $index, 0, ( $tuples[$_][2] ) );
				$tuples[$_][1] =~ s/^ $self->{project_dir} //sxm;
				$self->{list}->SetItem( $index,   1, ( $tuples[$_][1] ) );
				$self->{list}->SetItem( $index++, 2, ( $tuples[$_][3] ) );

			}
		}

		Padre::Util::tidy_list( $self->{list} );
	}

	# }
	return;
}


1;

__END__
