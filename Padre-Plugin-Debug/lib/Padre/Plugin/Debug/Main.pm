package Padre::Plugin::Debug::Main;

use 5.010;
use strict;
use warnings;

# Turn on $OUTPUT_AUTOFLUSH
$| = 1;
use diagnostics;
use utf8;

use Padre::Wx                         ();
use Padre::Plugin::Debug::FBP::MainFB ();
use Padre::Current                    ();
use Padre::Util                       ();
use Padre::Logger qw(TRACE DEBUG);

use Data::Printer { caller_info => 1, colored => 1, };
our $VERSION = '0.13';
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
	$self->{breakpoints_visable}  = 0;

	# Setup the debug button icons
	# $self->{sub_names}->Disable;
	# $self->{sub_name_regex}->Disable;
	# $self->{backtrace}->Disable;
	# $self->{list_actions}->Disable;
	# $self->{show_buffer}->Disable;
	
	$self->{launch_debug}->SetBitmapLabel( Padre::Wx::Icon::find('actions/morpho3') );
	$self->{launch_debug}->Enable;
	
	$self->{step_in}->SetBitmapLabel( Padre::Wx::Icon::find('actions/step_in') );
	$self->{step_in}->Disable;

	$self->{step_over}->SetBitmapLabel( Padre::Wx::Icon::find('actions/step_over') );
	$self->{step_over}->Disable;

	$self->{step_out}->SetBitmapLabel( Padre::Wx::Icon::find('actions/step_out') );
	$self->{step_out}->Disable;

	$self->{run_till}->SetBitmapLabel( Padre::Wx::Icon::find('actions/run_till') );
	$self->{run_till}->Disable;

	$self->{set_breakpoints}->SetBitmapLabel( Padre::Wx::Icon::find('actions/breakpoints') );
	$self->{set_breakpoints}->Enable;

	# $self->{trace}->Disable;

	$self->{display_value}->SetBitmapLabel( Padre::Wx::Icon::find('stock/code/stock_macro-watch-variable') );
	$self->{display_value}->Disable;

	$self->{quit_debugger}->SetBitmapLabel( Padre::Wx::Icon::find('actions/red_cross') );
	$self->{quit_debugger}->Disable;

	return;
}

########
# Event check_debugger_checked
########
sub check_debugger_checked {
	my ( $self, $event ) = @_;
	my $main = $self->main;

	# Construct breakpoint panel if it is not there
	unless ( $self->{debugger} ) {
		require Padre::Plugin::Debug::Panel::Debugger;
		$self->{debugger} = Padre::Plugin::Debug::Panel::Debugger->new($main);
	}

	if ( $self->{check_debugger}->GetValue ) {

		$main->right->show( $self->{debugger} );

		$self->{debugger}->{debug}->Show;
		$self->{debugger}->{debug}->Enable;
		# $self->{step_in}->Enable;
		# $self->{step_over}->Enable;
		# $self->{step_out}->Enable;
		# $self->{run_till}->Enable;
		# $self->{display_value}->Enable;
		$self->{quit_debugger}->Enable;

	} else {

		$main->right->hide( $self->{debugger} );

		$self->{debugger}->debug_quit;
		# $self->{step_in}->Disable;
		# $self->{step_over}->Disable;
		# $self->{step_out}->Disable;
		# $self->{run_till}->Disable;
		# $self->{display_value}->Disable;
		# $self->{trace}->Disable;
		$self->{debugger}->show_debug_output(0);

	}

	$self->aui->Update;

	return;
}

########
# Event Handler on_breakpoints_clicked
########
sub check_breakpoints_checked {
	my ( $self, $event ) = @_;
	my $main = $self->main;

	# Construct breakpoint panel if it is not there
	unless ( $self->{panel_breakpoints} ) {
		require Padre::Plugin::Debug::Panel::Breakpoints;
		$self->{panel_breakpoints} = Padre::Plugin::Debug::Panel::Breakpoints->new($main);
	}

	if ( $self->{check_breakpoints}->GetValue ) {
		$main->left->show( $self->{panel_breakpoints} );
		# $self->{set_breakpoints}->Enable;
	} else {
		$main->left->hide( $self->{panel_breakpoints} );
		# $self->{set_breakpoints}->Disable;
		delete $self->{panel_breakpoints};
	}

	$self->aui->Update;

	return;
}


#######
# Clean up our Classes, Padre::Plugin, POD out of date as of v0.84
#######
sub plugin_disable {
	my $self = shift;

	# Close the dialog if it is hanging around
	delete $self->{panel_breakpoints};
	$self->{debugger}->show_debug_output(0);
	$self->aui->Update;
	
	# Unload all our child classes
	$self->unload(
		qw{
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

##########################
# event handlers for simulation button bar
#######
# sub launch_debug_clicked
#######
sub launch_debug_clicked {
	my $self = shift;
	
	$self->{check_breakpoints}->SetValue(1);
	$self->check_breakpoints_checked();
	$self->{check_debugger}->SetValue(1);
	$self->check_debugger_checked();
	$self->{debugger}->on_debug_clicked();
	
	return; 
}
#######
# sub step_in_clicked
#######
sub step_in_clicked {
	my $self = shift;

	# TRACE('step_in_clicked') if DEBUG;
	# $self->{debugger}->debug_step_in();
	# $self->{step_over}->Enable;
	# $self->{step_out}->Enable;
	# $self->{run_till}->Enable;
	# $self->{display_value}->Enable;
	# $self->{quit_debugger}->Enable;
	# $self->{trace}->Enable;
	# $self->{sub_names}->Enable;
	# $self->{sub_name_regex}->Enable;
	# $self->{backtrace}->Enable;
	# $self->{list_actions}->Enable;
	# $self->{show_buffer}->Enable;

	return;
}
#######
# sub step_over_clicked
#######
sub step_over_clicked {
	my $self = shift;

	# TRACE('step_over_clicked') if DEBUG;
	# $self->{debugger}->debug_step_over;

	return;
}
#######
# sub step_out_clicked
#######
sub step_out_clicked {
	my $self = shift;

	# TRACE('step_out_clicked') if DEBUG;
	# $self->{debugger}->debug_step_out;

	return;
}
#######
# sub run_till_clicked
#######
sub run_till_clicked {
	my $self = shift;

	# TRACE('run_till_clicked') if DEBUG;
	# $self->{debugger}->debug_run_till;

	return;
}
#######
# event handler breakpoint_clicked
#######
sub set_breakpoints_clicked {
	my $self = shift;
	my $main = $self->main;

	TRACE('set_breakpoints_clicked') if DEBUG;
	if ( $self->{panel_breakpoints} ) {
	$self->{panel_breakpoints}->set_breakpoints_clicked();
} else {
	require Padre::Plugin::Debug::Breakpoints;
	Padre::Plugin::Debug::Breakpoints->set_breakpoints_clicked();
}
	return;
}
#######
# sub display_value
#######
sub display_value_clicked {
	my $self = shift;

	# TRACE('display_value') if DEBUG;
	# $self->{debugger}->display_value();

	return;
}
#######
# sub quit_debugger_clicked
#######
sub quit_debugger_clicked {
	my $self = shift;
	my $main = $self->main;

	TRACE('quit_debugger_clicked') if DEBUG;
	$self->{debugger}->debug_quit;
	# $self->{step_over}->Disable;
	# $self->{step_out}->Disable;
	# $self->{run_till}->Disable;
	# $self->{display_value}->Disable;
	# $self->{trace}->Disable;

	$self->{debugger}->show_debug_output(0);

	return;
}

#########################
# event handlers for debug output options
#######
# sub trace_clicked
#######
# sub trace_checked {
	# my ( $self, $event ) = @_;

# # 	if ( $event->IsChecked ) {
		# $self->{debugger}->display_trace(1);
	# } else {
		# $self->{debugger}->display_trace(0);
	# }

# # 	return;
# }
#######
# sub show_buffer_clicked
#######
# sub show_buffer_clicked {
	# my $self = shift;

# # 	$self->{debugger}->display_buffer();

# # 	return;
# }
#######
# sub_names_clicked
#######
# sub sub_names_clicked {
	# my $self = shift;

# # 	$self->{debugger}->display_sub_names( $self->{sub_name_regex}->GetValue() );

# # 	return;
# }
#######
# sub backtrace_clicked
#######
# sub backtrace_clicked {
	# my $self = shift;

# # 	$self->{debugger}->display_backtrace();

# # 	return;
# }
#######
# sub list_actions_clicked
#######
# sub list_actions_clicked {
	# my $self = shift;

# # 	$self->{debugger}->display_list_actions();

# # 	return;
# }

1;

__END__

=pod

=head1 STATUS

waiting until this Plug-in is working before migrating into Padre ( => 0.93 ) 
don't want to muck trunk.

To view Padre::DB::DebugBreakpoints use P-P-Cookbook::Recipie04 in trunk

We can now add and delete breakpoints via icon in debug simulation and Breakpoint panel.

Load breakpoints for current file, on load of Breakpoint panel.

Get breakpoint panel to only show current file and current project bp's only, 
inspired by vcs options

the debugger loads breakpoints from DB when started, for all files in current project. 
when debugger loads a new file ( current ) the current files BP's are add to the debugger, 
use L to see this.

changed breakpoint margin marker to ... so as to co-exist with diff margin markers,
and avoid information contamination due to colour washout of previous SMALLRECT.
Add Gray for not active with switched by debugger, also added new home made icons for step_....

add functionality from trunk so all icons mimic current debug implementation

look at displaying variables yes, but in a nice table (y 0) working

debug-output only visable when debugger running, on start of new debug first displays debugger help

Added butons with color leters to corespond to debugers actions.

=head1 FeedBack

what options should be in Debugger Panel / Debug-Output Options

room for 3 more using coloured letters



=head1 BUGS AND LIMITATIONS 

normal editor modifications do not update the DB,
( due to DB storing absolute values and editor is relative )
will need to look in future at features and background task to do this.

Current thinking would be to compare bp time-stamp to History time-stamp if it had one

=head2 debug options X & V sometimes produce the following

	You can't FIRSTKEY with the %~ hash at /home/kevin/perl5/perlbrew/perls/perl-5.14.1/lib/5.14.1/dumpvar.pl line 380
		...propagated at /home/kevin/perl5/perlbrew/perls/perl-5.14.1/lib/5.14.1/perl5db.pl line 2438.
	 at /home/kevin/perl5/perlbrew/perls/perl-5.14.1/lib/5.14.1/perl5db.pl line 2438
		DB::DB called at sandbox 06 line 29
	Debugged program terminated.  Use q to quit or R to restart,
	  use o inhibit_exit to avoid stopping after program termination,
	  h q, h R or h o to get additional info.

=head2 entities in file names

	Printing in line 636 of /home/kevin/perl5/perlbrew/perls/perl-5.14.1/lib/site_perl/5.14.1/Debug/Client.pm:
	"/usr/src/Padre/Pad�e-Plugin-Debug/scripts/ExSewi.pm"
	Printing in line 146 of /usr/src/Padre/Padre-Plugin-Debug/lib/Padre/Plugin/Debug/Debugger.pm:
	"/usr/src/Padre/Pad�e-Plugin-Debug/scripts/ExSewi.pm"
	No such file or directory when trying to open '/usr/src/Padre/Pad�e-Plugin-Debug/scripts/ExSewi.pm' at /usr/src/Padre/Padre/lib/Padre/Wx/Main.pm line 4043.


=head1 TODO 

get panels to integrate with Padre, play nice=yes, still not finished

re-look at panel layout

Add methods to Debug::Client in trunk as and where needed

Change focus to Debugger-Output in bottom panel 

=head2 Tests & Notes

feedback required please

=head1 Method 


=cut
