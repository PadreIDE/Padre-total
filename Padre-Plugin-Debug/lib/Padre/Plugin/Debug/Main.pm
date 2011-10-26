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
use Padre::Logger qw(TRACE DEBUG);

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
	$self->{breakpoints_visable}  = 0;
	require Padre::Plugin::Debug::Debugger;
	$self->{debugger} = Padre::Plugin::Debug::Debugger->new($main);

	# $self->{debugger}->setup();

	# Setup the debug button icons

	$self->{sub_names}->Disable;
	$self->{sub_name_regex}->Disable;
	$self->{backtrace}->Disable;
	$self->{list_actions}->Disable;
	$self->{show_buffer}->Disable;
	

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

	$self->{trace}->Disable;

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
	my ( $self, $event ) = @_;
	my $main = $self->main;

	# Construct debug output panel if it is not there
	# unless ( $self->{panel_debug_output} ) {
	# require Padre::Plugin::Debug::DebugOutput;
	# $self->{panel_debug_output} = Padre::Plugin::Debug::DebugOutput->new($main);
	# }

	# # 	if ( $event->IsChecked ) {
	# $main->bottom->show( $self->{panel_debug_output} );
	# } else {
	# $main->bottom->hide( $self->{panel_debug_output} );
	# delete $self->{panel_debug_output};
	# }

	# # 	$self->aui->Update;

	return;
}

########
# Event Handler on_breakpoints_clicked
########
sub breakpoints_checked {
	my ( $self, $event ) = @_;
	my $main = $self->main;

	# Construct breakpoint panel if it is not there
	unless ( $self->{panel_breakpoints} ) {
		require Padre::Plugin::Debug::Panel::Breakpoints;
		$self->{panel_breakpoints} = Padre::Plugin::Debug::Panel::Breakpoints->new($main);
	}

	if ( $event->IsChecked ) {
		$main->left->show( $self->{panel_breakpoints} );
		$self->{set_breakpoints}->Enable;
		$self->{step_in}->Enable;
	} else {
		$main->left->hide( $self->{panel_breakpoints} );
		$self->{set_breakpoints}->Disable;
		delete $self->{panel_breakpoints};
	}

	$self->aui->Update;

	return;
}

#######
# sub_names_clicked
#######
sub sub_names_clicked {
	my $self = shift;

	$self->{debugger}->display_sub_names( $self->{sub_name_regex}->GetValue() );
	
	return;
}

#######
# sub backtrace_clicked
#######
sub backtrace_clicked {
	my $self = shift;

	$self->{debugger}->display_backtrace();
	
	return;
}
#######
# sub show_buffer_clicked
#######
sub show_buffer_clicked {
	my $self = shift;

	$self->{debugger}->display_buffer();
	
	return;
}
#######
# sub list_actions_clicked
#######
sub list_actions_clicked {
	my $self = shift;

	$self->{debugger}->display_list_actions();
	
	return;
}
#######
# Clean up our Classes, Padre::Plugin, POD out of date as of v0.84
#######
sub plugin_disable {
	my $self = shift;

	# Close the dialog if it is hanging around
	$self->unload_panel_breakpoints;

	# $self->unpanel_debug_output;

	# Unload all our child classes
	$self->unload(
		qw{
			Padre::Plugin::Debug::Panel::DebugOutput
			Padre::Plugin::Debug::FBP::DebugOutput
			Padre::Plugin::Debug::Panel::Breakpoints
			Padre::Plugin::Debug::FBP::Breakpoints
			Padre::Plugin::Debug::Panel::DebugVariable
			Padre::Plugin::Debug::FBP::DebugVariable
			Padre::Plugin::Debug::Debugger
			Debug::Client
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

	TRACE('step_in_clicked') if DEBUG;
	$self->{debugger}->debug_step_in();
	$self->{step_over}->Enable;
	$self->{step_out}->Enable;
	$self->{run_till}->Enable;
	$self->{display_value}->Enable;
	$self->{quit_debugger}->Enable;
	$self->{trace}->Enable;
	$self->{sub_names}->Enable;
	$self->{sub_name_regex}->Enable;
	$self->{backtrace}->Enable;
	$self->{list_actions}->Enable;
	$self->{show_buffer}->Enable;

	return;
}
#######
# sub step_over_clicked
#######
sub step_over_clicked {
	my $self = shift;

	TRACE('step_over_clicked') if DEBUG;
	$self->{debugger}->debug_step_over;

	return;
}
#######
# sub step_out_clicked
#######
sub step_out_clicked {
	my $self = shift;

	TRACE('step_out_clicked') if DEBUG;
	$self->{debugger}->debug_step_out;

	return;
}
#######
# sub run_till_clicked
#######
sub run_till_clicked {
	my $self = shift;

	TRACE('run_till_clicked') if DEBUG;
	$self->{debugger}->debug_run_till;

	return;
}
#######
# event handler breakpoint_clicked
#######
sub set_breakpoints_clicked {
	my $self = shift;

	TRACE('set_breakpoints_clicked') if DEBUG;
	$self->{panel_breakpoints}->set_breakpoints_clicked();

	return;
}
#######
# sub trace_clicked
#######
sub trace_checked {
	my ( $self, $event ) = @_;

	if ( $event->IsChecked ) {
		$self->{debugger}->display_trace(1);
	} else {
		$self->{debugger}->display_trace(0);
	}

	return;
}
#######
# sub display_value
#######
sub display_value_clicked {
	my $self = shift;

	TRACE('display_value') if DEBUG;
	$self->{debugger}->display_value();

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
	$self->{step_over}->Disable;
	$self->{step_out}->Disable;
	$self->{run_till}->Disable;
	$self->{display_value}->Disable;
	$self->{trace}->Disable;

	$main->left->hide( $self->{panel_breakpoints} );
	$self->{breakpoints}->SetValue(0);

	return;
}

1;

__END__

=pod

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

get panels to integrate with Padre, play nice=yes, still not finished

add functionality from trunk so all icons mimic current debug implementation

look at displaying variables yes, but in a nice table

=head1 Method 

=head2 Add the following to Debug::Client

the following diff holds changes to be applied to Debug::Client, 
until P-P-Debug is working in an initial form, I will just add the Patch here for now

=cut

--- /home/kevin/src/Padre/Debug-Client/lib/Debug/Client.pm
+++ /home/kevin/perl5/perlbrew/perls/perl-5.14.1/lib/site_perl/5.14.1/Debug/Client.pm
@@ -1,7 +1,12 @@
 package Debug::Client;
+
+use 5.010;
 use strict;
 use warnings;
-use 5.006;
+
+# Turn on $OUTPUT_AUTOFLUSH
+$| = 1;
+use diagnostics;
 
 our $VERSION = '0.12';
 
@@ -266,9 +271,31 @@
 
 =cut
 
+#T Produce a stack backtrace. 
 sub get_stack_trace {
 	my ($self) = @_;
 	$self->_send('T');
+	my $buf = $self->_get;
+
+	$self->_prompt( \$buf );
+	return $buf;
+}
+
+#t Toggle trace mode (see also the AutoTrace option).
+sub toggle_trace {
+	my ($self) = @_;
+	$self->_send('t');
+	my $buf = $self->_get;
+
+	$self->_prompt( \$buf );
+	return $buf;
+}
+
+# S [[!]pattern]    List subroutine names [not] matching pattern.
+sub list_subroutine_names {
+	my ($self, $pattern) = @_;
+	# print "D-C $pattern \n";
+	$self->_send("S $pattern");
 	my $buf = $self->_get;
 
 	$self->_prompt( \$buf );
@@ -302,12 +329,13 @@
 
 =cut
 
-
 sub set_breakpoint {
 	my ( $self, $file, $line, $cond ) = @_;
-
+	
 	$self->_send("f $file");
+	# $self->_send("b $file");
 	my $b = $self->_get;
+	# print $b . "\n";
 
 	# Already in t/eg/02-sub.pl.
 
@@ -316,6 +344,7 @@
 	# if it was successful no reply
 	# if it failed we saw two possible replies
 	my $buf    = $self->_get;
+	# print $buf . "\n";
 	my $prompt = $self->_prompt( \$buf );
 	if ( $buf =~ /^Subroutine [\w:]+ not found\./ ) {
 
@@ -332,6 +361,7 @@
 	return 1;
 }
 
+
 # apparently no clear success/error report for this
 sub remove_breakpoint {
 	my ( $self, $file, $line ) = @_;
@@ -362,6 +392,14 @@
 
 =cut
 
+sub show_breakpoints {
+	my ($self) = @_;
+
+	my $ret = $self->send_get('L');
+
+	return $ret;
+}
+
 sub list_break_watch_action {
 	my ($self) = @_;
 
@@ -369,6 +407,9 @@
 	if ( not wantarray ) {
 		return $ret;
 	}
+
+	# short cut for direct output
+	# return $ret;
 
 	# t/eg/04-fib.pl:
 	#  17:      my $n = shift;
@@ -446,6 +487,43 @@
 		return $data_ref;
 	}
 	die "Unknown parameter '$var'\n";
+}
+
+sub get_y_zero {
+	my $self = shift;
+
+	$self->_send("y 0");
+	my $buf = $self->_get;
+	$self->_prompt( \$buf );
+	return $buf;
+}
+
+#X [vars] Same as V currentpackage [vars] 
+sub get_x_vars {
+	my ($self, $pattern) = @_;
+	die "no pattern given\n" if not defined $pattern;
+	
+	$self->_send("X $pattern");
+	my $buf = $self->_get;
+	$self->_prompt( \$buf );
+	return $buf;
+}
+
+#V [pkg [vars]]
+
+# Display all (or some) variables in package (defaulting to main ) 
+# using a data pretty-printer (hashes show their keys and values so you see what's what, 
+# control characters are made printable, etc.). 
+# Make sure you don't put the type specifier (like $ ) there, just the symbol names, like this:
+
+sub get_v_vars {
+	my ($self, $pattern) = @_;
+	die "no pattern given\n" if not defined $pattern;
+	
+	$self->_send("V $pattern");
+	my $buf = $self->_get;
+	$self->_prompt( \$buf );
+	return $buf;
 }
 
 sub _parse_dumper {



