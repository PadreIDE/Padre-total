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
use Padre::Util                       ();
# use Padre::Logger qw(TRACE DEBUG);

use Data::Printer { caller_info => 1, colored => 1, };
our $VERSION = '0.02';
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
	my $main = $self->main;

	$self->{debug_output_visable} = 0;
	$self->{breakpoints_visable} = 0;
	require Padre::Plugin::Debug::Wx::Debugger;
	$self->{debugger} = Padre::Plugin::Debug::Wx::Debugger->new();
	
	# Setup the debug button icons

	$self->{step_in}->SetBitmapLabel( Padre::Wx::Icon::find('stock/code/stock_macro-stop-after-command') );
	$self->{step_in}->Enable;

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
# Event Handler on_debug_output_clicked
# this is a naff loading method,
########
sub on_debug_output_clicked {
	my ($self, $event) = @_;
	my $main = $self->main;

	# Construct debug output panel if it is not there
	unless($self->{panel_debug_output}) {
		require Padre::Plugin::Debug::DebugOutput;
		$self->{panel_debug_output} = Padre::Plugin::Debug::DebugOutput->new($main);
	}

	if($event->IsChecked) {
		$main->bottom->show( $self->{panel_debug_output} );
	} else {
		$main->bottom->hide( $self->{panel_debug_output} );
		delete $self->{panel_debug_output};
	}

# p $self->{debug_output_visable};

# # 	if ( $self->{debug_output_visable} == 1 ) {

# # todo turn off
		# $self->unload_panel_debug_output();
		
# # 		$self->{panel_debug_output}->disable($self);
		
# # 		$main->bottom->hide( $self->{panel_debug_output} );
		# delete $self->{panel_debug_output};
		
# # 		$self->{debug_output_visable} = 0;
		# $self->{step_in}->Disable;
		# $self->{display_value}->Disable;
		# $self->{quit_debugger}->Disable;
	# } else {

# # todo turn on
		# $self->load_panel_debug_output();
		
# # 		$self->{panel_debug_output}->enable($self);
		
# # 		$self->{debug_output_visable} = 1;
		# $self->{step_in}->Enable;
		# $self->{display_value}->Enable;
		# $self->{quit_debugger}->Enable;
	# }
	
	$self->aui->Update;

	return;
}
########
# Composed Method,
# Load Panel Debug Output,
#######
sub load_panel_debug_output {
	my $self = shift;
	my $main = $self->main;
	
require Padre::Plugin::Debug::DebugOutput;
	$self->{panel_debug_output} = Padre::Plugin::Debug::DebugOutput->new($main);
	$self->{panel_debug_output}->Show;
	$self->{debug_output_visable} = 1;

return;
}
########
# Composed Method,
# Unload Panel Debug Output,
#######
sub unload_panel_debug_output {
	my $self = shift;

# 	# Close the main dialog if it is hanging around
	if ( $self->{panel_debug_output} ) {
		$self->{panel_debug_output}->Destroy;
		delete $self->{panel_debug_output};
	}

$self->{debug_output_visable} = 0;

return 1;
}


########
# Event Handler on_breakpoints_clicked
########
sub on_breakpoints_clicked {
	my $self = shift;
	# my $main = $self->main;

	if ( $self->{breakpoints_visable} == 1 ) {

		#todo turn off
		$self->unload_panel_breakpoints();
		$self->{set_breakpoints}->Disable;
	} else {

		#todo turn on
		$self->load_panel_breakpoints();
		$self->{set_breakpoints}->Enable;
		$self->{step_in}->Enable;
	}

	return;
}
########
# Composed Method,
# Load Panel Breakpoints
#######
sub load_panel_breakpoints {
	my $self = shift;
	my $main = $self->main;

	require Padre::Plugin::Debug::Breakpoints;
	$self->{panel_breakpoints} = Padre::Plugin::Debug::Breakpoints->new($main);
	$self->{panel_breakpoints}->Show;
	$self->{breakpoints_visable} = 1;

	return;
}
########
# Composed Method,
# Unload Panel Breakpoints
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
	$self->unload_panel_breakpoints;
	$self->unpanel_debug_output;

	# Unload all our child classes
	$self->unload(
		qw{
			Padre::Plugin::Debug::DebugOutput
			Padre::Plugin::Debug::FBP::DebugOutput
			Padre::Plugin::Debug::Breakpoints
			Padre::Plugin::Debug::FBP::Breakpoints
			Padre::Plugin::Debug::Wx::Debugger
			}
	);

	$self->SUPER::plugin_disable(@_);
	return 1;
}


#######
# sub step_in_clicked
#######
sub step_in_clicked {
	my $self = shift;
	
	$self->{debugger}->debug_perl_step_in;
	$self->{step_over}->Enable;
	$self->{step_out}->Enable;
	$self->{run_till}->Enable;
	$self->{display_value}->Enable;
	$self->{quit_debugger}->Enable;
	return;
}
#######
# sub step_over_clicked
#######
sub step_over_clicked {
	my $self = shift;

	say 'step_over_clicked';
	$self->{debugger}->debug_perl_step_over;

	return;
}
#######
# sub step_out_clicked
#######
sub step_out_clicked {
	my $self = shift;

	say 'step_out_clicked';
	$self->{debugger}->debug_perl_step_out;

	return;
}
#######
# sub run_till_clicked
#######
sub run_till_clicked {
	my $self = shift;
	
	say 'run_till_clicked';
	$self->{debugger}->debug_perl_run_till;

	return;
}
#######
# event handler breakpoint_clicked
#######
sub set_breakpoints_clicked {
	my $self = shift;
	
	say 'set_breakpoints_clicked';
	$self->{panel_breakpoints}->set_breakpoints_clicked();

	return;
}
#######
# sub display_value
#######
sub display_value_clicked {
	my $self = shift;

	say 'display_value';
	$self->{panel_debug_output}->debug_out('step in');
	# $self->{debugger}->debug_perl_display_value;

	return;
}
#######
# sub quit_debugger_clicked
#######
sub quit_debugger_clicked {
	my $self = shift;
	
	say 'quit_debugger_clicked';
	$self->{debugger}->debug_perl_quit;
	$self->{step_over}->Disable;
	$self->{step_out}->Disable;
	$self->{run_till}->Disable;
	$self->{display_value}->Disable;
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

changed breakpoint margin marker to ... so as to co-exist with diff margin markers,
and avoid information contamination due to colour washout of previous SMALLRECT.

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