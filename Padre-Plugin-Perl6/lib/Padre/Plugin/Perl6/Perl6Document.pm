package Padre::Plugin::Perl6::Perl6Document;

use 5.010;
use strict;
use warnings;

use Padre::Wx ();

our $VERSION = '0.43';
our @ISA     = 'Padre::Document';

# max lines to display in a calltip
my $CALLTIP_DISPLAY_COUNT = 10;

# colorize timer to make sure that colorize tasks are scheduled properly...
my $COLORIZE_TIMER;
my $COLORIZE_TIMEOUT = 100; # wait n-millisecond before starting the Perl6 colorize task

sub text_with_one_nl {
	my $self = shift;
	my $text = $self->text_get;
	my $nlchar = "\n";
	if ( $self->get_newline_type eq 'WIN' ) {
		$nlchar = "\r\n";
	}
	elsif ( $self->get_newline_type eq 'MAC' ) {
		$nlchar = "\r";
	}
	$text =~ s/$nlchar/\n/g;
	return $text;
}

# colorizes a Perl 6 document in a timer
# one at a time;
# now the user can choose between PGE and STD colorizers
# via the preferences
sub colorize {
	my $self = shift;
	
	my $config = Padre::Plugin::Perl6::plugin_config();
	if($config->{p6_highlight} || $self->{force_p6_highlight}) {
	
		unless($COLORIZE_TIMER) {
			my $timer_id = Wx::NewId();
			my $main = Padre->ide->wx->main;
			$COLORIZE_TIMER = Wx::Timer->new($main, $timer_id);
			Wx::Event::EVT_TIMER(
				$main, $timer_id, 
				sub { 
					# temporary overlay using the parse tree given by parrot
					my $colorizer = $config->{colorizer};
					my $task;
					if($colorizer eq 'STD') {
						# Create an STD coloring task 
						require Padre::Plugin::Perl6::Perl6StdColorizerTask;
						$task = Padre::Plugin::Perl6::Perl6StdColorizerTask->new(
							text => $self->text_with_one_nl,
							editor => $self->editor,
							document => $self);
					} else {
						# Create a PGE coloring task
						require Padre::Plugin::Perl6::Perl6PgeColorizerTask;
						$task = Padre::Plugin::Perl6::Perl6PgeColorizerTask->new(
							text => $self->text_with_one_nl,
							editor => $self->editor,
							document => $self);
					}
					# hand off to the task manager
					$task->schedule();

					# and let us schedule that it is running properly or not
					if($task->is_broken) {
						# let us reschedule colorizing task to a later date..
						$COLORIZE_TIMER->Stop;
						$COLORIZE_TIMER->Start( $COLORIZE_TIMEOUT, Wx::wxTIMER_ONE_SHOT );
					}
				},
			);
		}

		# let us reschedule colorizing task to a later date..
		$COLORIZE_TIMER->Stop;
		$COLORIZE_TIMER->Start( $COLORIZE_TIMEOUT, Wx::wxTIMER_ONE_SHOT );
	}
}

# get Perl6 (rakudo) command line for "Run script" F5 Padre menu item
sub get_command {
	my $self     = shift;

	my $filename = $self->filename;
	require Padre::Plugin::Perl6::Util;
	my $perl6    = Padre::Plugin::Perl6::Util::get_perl6();
	
	if(not $perl6) {
		my $main = Padre->ide->wx->main;
		$main->error("Either perl6 needs to be in the PATH or RAKUDO_DIR must point to the directory of the Rakudo checkout.");
	}

	return qq{"$perl6" "$filename"};
}

# Checks the syntax of a Perl document.
# Documented in Padre::Document!
# Implemented as a task. See Padre::Plugin::Perl6::Perl6SyntaxChecker
sub check_syntax {
	my $self  = shift;
	my %args  = @_;
	$args{background} = 0;
	return $self->_check_syntax_internals(\%args);
}

sub check_syntax_in_background {
	my $self  = shift;
	my %args  = @_;
	$args{background} = 1;
	return $self->_check_syntax_internals(\%args);
}

sub _check_syntax_internals {
	my $self = shift;
	my $args  = shift;

	my $text = $self->text_with_one_nl;
	unless ( defined $text and $text ne '' ) {
		return [];
	}

	# Do we really need an update?
	require Digest::MD5;
	my $md5 = Digest::MD5::md5_hex( Encode::encode_utf8($text) );
	unless ( $args->{force} ) {
		if ( defined( $self->{last_syncheck_md5} )
			and $self->{last_syncheck_md5} eq $md5 )
		{
			return;
		}
	}
	$self->{last_syncheck_md5} = $md5;

	require Padre::Plugin::Perl6::Perl6SyntaxCheckerTask;
	my $task = Padre::Plugin::Perl6::Perl6SyntaxCheckerTask->new(
		notebook_page => $self->editor,
		text => $text,
		issues => $self->{issues},
		( exists $args->{on_finish} ? (on_finish => $args->{on_finish}) : () ),
	);
	if ($args->{background}) {
		# asynchroneous execution (see on_finish hook)
		$task->schedule();
		return();
	}
	else {
		# serial execution, returning the result
		return() if $task->prepare() =~ /^break$/;
		$task->run();
		return $task->{syntax_check};
	}
	return;
}

sub keywords {
	my $self = shift;
	if (! defined $self->{keywords}) {
		#Get keywords from Plugin object
		my $manager = Padre->ide->plugin_manager;
		if($manager) {
			my $plugin = $manager->plugins->{'Perl6'};
			if($plugin) {
				my %perl6_functions = %{$plugin->object->{perl6_functions}};
				foreach my $function (keys %perl6_functions) {
					my $docs = $perl6_functions{$function};
					# limit calltip size to n-lines
					my @lines = split /\n/, $docs;
					if(scalar @lines > $CALLTIP_DISPLAY_COUNT) {
						$docs = (join "\n", @lines[0..$CALLTIP_DISPLAY_COUNT-1]) .
							"\n...";
					}
					$self->{keywords}->{$function} = {
						'cmd' => $docs,
						'exp' => '',
					};
				}
			 }
		}
	}
	return $self->{keywords};
}

sub comment_lines_str { return '#' }

sub event_on_right_down {
	my ($self, $editor, $menu, $event ) = @_;

	my $current_line_no = $editor->GetCurrentLine;
	my $main = $editor->main;
	$menu->AppendSeparator;

	foreach my $issue ( @{$self->{issues}} ) {
		my $issue_line_no = $issue->{line} - 1;
		if($issue_line_no == $current_line_no) {
			my $issue_msg = $issue->{msg};
			my $comment_error_action = 0;
			if($issue_msg =~ /^\s*Variable\s+(.+?)\s+is not predeclared at/i) {
				
				my $var_name = $1;
				Wx::Event::EVT_MENU(
					$main, 
					$menu->Append( -1, sprintf( Wx::gettext("Insert declaration for '%s'"), $var_name) ),
					sub { 
						#XXX-implement insert variable declaration
					},
				);
				$comment_error_action = 1;
			
			} elsif($issue_msg =~ /^Undeclared routine:\s+(.+?)\s+used/i) {
				
				my $routine_name = $1;
				#XXX-add more control keywords
				my @keywords = ('if','unless','loop','for');
				foreach my $keyword (@keywords) {
					if($keyword eq $routine_name) {
						Wx::Event::EVT_MENU(
							$main, 
							$menu->Append( -1, sprintf( Wx::gettext("Did u mean if (...) { }?"), $keyword) ),
							sub { 
								#XXX-implement add space before brace
							},
						);
						
						last;
					}
				}
				Wx::Event::EVT_MENU(
					$main, 
					$menu->Append( -1, sprintf( Wx::gettext("Insert routine '%s'"), $routine_name) ),
					sub { 
						#XXX-implement insert routine
					},
				);
				$comment_error_action = 1;
			
			} elsif($issue_msg =~ /^Obsolete use of . to concatenate strings/i) {

				Wx::Event::EVT_MENU(
					$main, 
					$menu->Append( -1, Wx::gettext("Use ~ instead of . for string concatenation") ),
					sub { 
						#XXX-implement use ~ instead of . for string concatenation
					},
				);
				$comment_error_action = 1;
			
			} elsif($issue_msg =~ /^Obsolete use of -> to call a method/i) {

				Wx::Event::EVT_MENU(
					$main, 
					$menu->Append( -1, Wx::gettext("Use . instead of -> for method call") ),
					sub { 
						#XXX-implement Use . instead of -> for method call
					},
				);
				$comment_error_action = 1;
			
			} elsif($issue_msg =~ /^Obsolete use of C++ constructor syntax/i) {

				Wx::Event::EVT_MENU(
					$main, 
					$menu->Append( -1, Wx::gettext("Use Perl 6 constructor syntax") ),
					sub { 
						#XXX-implement Use Perl 6 constructor syntax
					},
				);
				$comment_error_action = 1;
			
			}
			
			if($comment_error_action) {
				Wx::Event::EVT_MENU(
					$main, 
					$menu->Append( -1, Wx::gettext("Comment current error") ),
					sub {
						#XXX-implement comment current error
					},
				);
			}
			
		}
	}

	return;
}

sub get_outline {
	my $self = shift;
	my %args = @_;

	my $tokens = $self->{tokens};
	
	if(not defined $tokens) {
		return;
	}
	
	my $text = $self->text_get;
	unless ( defined $text and $text ne '' ) {
		return [];
	}

	# Do we really need an update?
	require Digest::MD5;
	my $md5 = Digest::MD5::md5_hex( Encode::encode_utf8($text) );
	unless ( $args{force} ) {
		if ( defined( $self->{last_outline_md5} )
			and $self->{last_outline_md5} eq $md5 )
		{
			return;
		}
	}
	$self->{last_outline_md5} = $md5;

	require Padre::Plugin::Perl6::Perl6OutlineTask;
	my $task = Padre::Plugin::Perl6::Perl6OutlineTask->new(
		editor => $self->editor,
		text   => $text,
		tokens => $tokens,
	);

	# asynchronous execution (see on_finish hook)
	$task->schedule;
	return;
}

1;

# Copyright 2008 Gabor Szabo.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.
