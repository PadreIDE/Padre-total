package Padre::Plugin::Debug::Main;

use 5.010;
use strict;
use warnings;

# Turn on $OUTPUT_AUTOFLUSH
$| = 1;
use diagnostics;

use Padre::Wx                         ();
use Padre::Plugin::Debug::FBP::MainFB ();
use Padre::Current                    ();
# use Padre::Plugin::Debug::Breakpointspl;
# use Padre::Util                       ();
# use Padre::Logger qw(TRACE DEBUG);

use Data::Printer { caller_info => 1, colored => 1, };
our $VERSION = '0.02';
use parent qw( Padre::Plugin::Debug::FBP::MainFB );

#TODO there must be a better way than this
my @all_bp;

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

	# Setup the debug button icons

	$self->{step_in}->SetBitmapLabel( Padre::Wx::Icon::find('stock/code/stock_macro-stop-after-command') );
	$self->{step_in}->Disable;

	$self->{step_over}->SetBitmapLabel( Padre::Wx::Icon::find('stock/code/stock_macro-stop-after-procedure') );
	$self->{step_over}->Disable;

	$self->{step_out}->SetBitmapLabel( Padre::Wx::Icon::find('stock/code/stock_macro-jump-back') );
	$self->{step_out}->Disable;

	$self->{run_till}->SetBitmapLabel( Padre::Wx::Icon::find('stock/code/stock_tools-macro') );
	$self->{run_till}->Disable;

	$self->{set_breakpoints}->SetBitmapLabel( Padre::Wx::Icon::find('stock/code/stock_macro-insert-breakpoint') );
	$self->{set_breakpoints}->Disable;

	$self->{display_value}->SetBitmapLabel( Padre::Wx::Icon::find('stock/code/stock_macro-watch-variable') );
	$self->{display_value}->Disable;

	$self->{quit_debugger}->SetBitmapLabel( Padre::Wx::Icon::find('actions/stop') );
	$self->{quit_debugger}->Disable;

	# $self->_setup_db();

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
		$self->{set_breakpoints}->Disable;
	} else {

		#todo turn on
		$self->load_panel_breakpoints();
		$self->{set_breakpoints}->Enable;
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

	require Padre::Plugin::Debug::Breakpoints;
	$self->{panel_breakpoints} = Padre::Plugin::Debug::Breakpoints->new($main);

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
			Padre::Plugin::Debug::Breakpoints
			Padre::Plugin::Debug::FBP::Breakpoints
			}
	);

	$self->SUPER::plugin_disable(@_);
	return 1;
}


#######
# event handler breakpoint_clicked
#######
sub set_breakpoints_clicked {
	my $self    = shift;
	# my $main    = $self->main;
	
# # 	require Padre::Plugin::Debug::Breakpointspl;
	# Padre::Plugin::Debug::Breakpointspl::set_breakpoints_clicked();
	$self->{panel_breakpoints}->set_breakpoints_clicked();

	# my $current = $main->current;

# # 	# $self->running or return;
	# my $editor = Padre::Current->editor;
	# $self->{bp_file} = $editor->{Document}->filename;
	# $self->{bp_line} = $editor->GetCurrentLine + 1;

# # 	# p $current->project->root;
	# # dereferance array and test for contents
	# if ($#{ $self->{debug_breakpoints}
				# ->select("WHERE filename = \"$self->{bp_file}\" AND line_number = \"$self->{bp_line}\"")
		# } >= 0
		# )
	# {
		# say 'delete me';
		# $editor->MarkerDelete( $self->{bp_line} - 1, Padre::Constant::MARKER_BREAKPOINT() );
		# $self->_delete_bp_db();

# # 	} else {
		# say 'create me';
		# $self->{bp_active} = 1;
		# $editor->MarkerAdd( $self->{bp_line} - 1, Padre::Constant::MARKER_BREAKPOINT() );
		# $self->_add_bp_db();
	# }

	return;
}


########
# Debug Breakpoint DB
########

#######
# internal method _setup_db connector
#######
# sub _setup_db {
	# my $self = shift;

# # 	# set padre db relation
	# $self->{debug_breakpoints} = ('Padre::DB::DebugBreakpoints');

# # 	# p $self->{debug_breakpoints};
	# # p $self->{debug_breakpoints}->table_info;
	# # p $self->{debug_breakpoints}->select;
	# return;
# }

#######
# internal method _add_bp_db
#######
# sub _add_bp_db {
	# my $self = shift;

# # 	$self->{debug_breakpoints}->create(
		# filename    => $self->{bp_file},
		# line_number => $self->{bp_line},
		# active      => $self->{bp_active},
		# last_used   => time(),
	# );

# # 	p $self->{debug_breakpoints}->select;
	# return;
# }

#######
# internal method _delete_bp_db
#######
# sub _delete_bp_db {
	# my $self = shift;

# # 	$self->{debug_breakpoints}->delete("WHERE filename = \"$self->{bp_file}\" AND line_number = \"$self->{bp_line}\"");

# # 	# p $self->{debug_breakpoints}->select;
	# return;
# }

#######################################
# only yaml below to be deleted later
#######################################

#######
# event handler breakpoint_clicked
#######
sub breakpoint_clicked {
	my $self = shift;
	say 'breakpoint_clicked: ' . $self->bp_line_number->GetValue();
	$self->add_bp_marker( $self->bp_line_number->GetValue() );
	$self->overwirte_padre_yaml();
	# $self->_add_bp_db();
	return;
}

########
# composed method add_bp_marker
########
sub add_bp_marker {
	my $self        = shift;
	my $line_number = shift;

	my $main = $self->main;

	# $self->running or return;

	my $editor = Padre::Current->editor;
	my $file   = $editor->{Document}->filename;
	p $file;

	# my $row    = $editor->GetCurrentLine + 1;
	my $row = $line_number;

	$editor->MarkerAdd( $row - 1, Padre::Constant::MARKER_BREAKPOINT() );

	# TODO: This should be the condition I guess

	my %bp = ( filename => $file, line_number => $line_number, active => 1, );
	p %bp;

	$self->{bp_file}   = $file;
	$self->{bp_line}   = $line_number;
	$self->{bp_active} = 1;

	$self->bp_data( $file, $line_number, 1 );
	return;
}


########
# YAML
########
sub get_padre_yaml {
	my $self    = shift;
	my $main    = $self->main;
	my $current = $main->current;

	# p $current->project;
	p $current->project->root;

	# p $current->project->padre_yml;

	my $padre_yml;
	if ( $current->project->padre_yml ) {
		$padre_yml = $current->project->padre_yml;
	} else {
		$padre_yml = $current->project->root . '/padre.yml';
	}

	p $padre_yml;

	return $padre_yml;
}


sub overwirte_padre_yaml {
	my $self = shift;

	my $padre_yaml_url = $self->get_padre_yaml();

	if ( -e $padre_yaml_url ) {
		say 'found padre.yml';
	}

	use YAML::Tiny;

	# Create a YAML file
	my $debug_yaml = YAML::Tiny->new();

	# reading a non exsisting file cause an error
	# $debug_yaml = YAML::Tiny->read( $padre_yaml_url );

	$debug_yaml->[0] = [@all_bp];
	p $debug_yaml;

	#NB this will overwirte the file $padre_yaml_url
	$debug_yaml->write($padre_yaml_url);

	return;
}

########
#
########
sub bp_data {
	my $self     = shift;
	my $file_url = shift;
	my $bp_line  = shift;
	my $active   = shift;

	push @all_bp, { filename => $file_url, line_number => $bp_line, active => $active, };
	p @all_bp;

	return;
}

1;

__END__


=head1 STATUS

waiting until this Plug-in is working before migrating into Padre ( => 0.95 ) 
don't want to muck trunk.

To view Padre::DB::DebugBreakpoints use P-P-Cookbook::Recipie04 in trunk

We can now add and delete breakpoints via icon in debug simulation and Breakpoint panel.

Load breakpoints for current file, on load of Breakpoint panel.

Get breakpoint panel to only show current file and current project bp's only, 
inspired by vcs options


=head1 BUGS AND LIMITATIONS 

normal editor modifications do not update the DB,
( due to DB storing absolute values and editor is relative )
will need to look in future at features and background task to do this.

Current thinking would be to compare bp time-stamp to History time-stamp if it had one


=head1 TODO 

look at debug having its own margin (shared with code folding) and new icons, 
current thinking two dots a coloured one for active and Gray for not active 
with switch in breakpoint panel 

get panels to integrate with Padre, play nice?

add functionality from trunk so all icons mimic current debug implementation

look at displaying variables