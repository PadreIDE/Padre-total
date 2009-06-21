package Padre::Plugin::Perl6::Perl6Document;

use 5.010;
use strict;
use warnings;

use Padre::Wx ();

our $VERSION = '0.44';
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

#
# Guess the new line for the current document
# can return \r, \r\n, or \n
#
sub guess_newline {
	my $self = shift;
	
	require Padre::Util;
	my $doc_new_line_type = Padre::Util::newline_type($self->text_get);
	my $new_line;
	if($doc_new_line_type eq "WIN") {
		$new_line = "\r\n";
	} elsif($doc_new_line_type eq "MAC") {
		$new_line = "\r";
	} else {
		#NONE, UNIX or MIXED
		$new_line = "\n";
	}
	
	return $new_line;
}

#
# Tries to find quick fixes for errors in the current line
#
sub _find_quick_fix {
	my ($self, $editor) = @_;
	
	my $new_line = $self->guess_newline;
	my $current_line_no = $editor->GetCurrentLine;
	
	my @items = ();
	print "Number of issues: " . scalar @{$self->{issues}} . "\n";
	foreach my $issue ( @{$self->{issues}} ) {
		my $issue_line_no = $issue->{line} - 1;
		if($issue_line_no == $current_line_no) {
			my $issue_msg = $issue->{msg};
			my $comment_error_action = 0;
			if($issue_msg =~ /^\s*Variable\s+(.+?)\s+is not predeclared at/i) {
				
				my $var_name = $1;

				push @items, {
					text     => sprintf( Wx::gettext("Insert declaration for %s"), $var_name),
					listener => sub { 
						#Insert a variable declaration before the start of the current line
						my $line_start = $editor->PositionFromLine( $current_line_no );
						$editor->InsertText($line_start, "my $var_name;$new_line");
					},
				};
				$comment_error_action = 1;
			
			} elsif($issue_msg =~ /^Undeclared routine:\s+(.+?)\s+used/i) {
				
				my $routine_name = $1;
				#flow control keywords
				my @flow_control_keywords = (
					'for', 'given', 'if', 'loop', 'repeat', 
					'unless', 'until', 'when', 'while',
				);
				foreach my $keyword (@flow_control_keywords) {
					if($keyword eq $routine_name) {
						push @items, {
							text     => sprintf( Wx::gettext("Insert a space after %s"), $keyword ),
							listener => sub { 
								#Insert a space before brace
								my $line_start = $editor->PositionFromLine( $current_line_no );
								my $line_end   = $editor->GetLineEndPosition( $current_line_no );
								my $line_text  = $editor->GetTextRange($line_start, $line_end);
								$line_text =~ s/$keyword\(/$keyword \(/;
								$editor->SetSelection( $line_start, $line_end );
								$editor->ReplaceSelection( $line_text );
							},
						};
						
						last;
					}
				}
				push @items, {
					text     => sprintf( Wx::gettext("Insert routine %s"), $routine_name),
					listener => sub { 
						#Insert an empty routine definition before the current line
						my $line_start = $editor->PositionFromLine( $current_line_no );
						$editor->InsertText($line_start, 
							"sub $routine_name {$new_line\t#XXX-implement$new_line}$new_line");
					},
				};
				$comment_error_action = 1;
			
			} elsif($issue_msg =~ /^Obsolete use of . to concatenate strings/i) {

				push @items, {
					text     => Wx::gettext("Use ~ instead of . for string concatenation"),
					listener => sub { 
						#replace first '.' with '~' in the current line
						my $line_start = $editor->PositionFromLine( $current_line_no );
						my $line_end   = $editor->GetLineEndPosition( $current_line_no );
						my $line_text  = $editor->GetTextRange($line_start, $line_end);
						$line_text =~ s/\./~/;
						$editor->SetSelection( $line_start, $line_end );
						$editor->ReplaceSelection( $line_text );
					},
				};
				$comment_error_action = 1;
			
			} elsif($issue_msg =~ /^Obsolete use of -> to call a method/i) {

				push @items, {
					text     => Wx::gettext("Use . instead of -> for method call"),
					listener => sub { 
						#Replace first '->' with '.' in the current line
						my $line_start = $editor->PositionFromLine( $current_line_no );
						my $line_end   = $editor->GetLineEndPosition( $current_line_no );
						my $line_text  = $editor->GetTextRange($line_start, $line_end);
						$line_text =~ s/\-\>/\./;
						$editor->SetSelection( $line_start, $line_end );
						$editor->ReplaceSelection( $line_text );
					},
				};
				$comment_error_action = 1;
			
			} elsif($issue_msg =~ /^Obsolete use of C\+\+ constructor syntax/i) {

				push @items, {
					text     => Wx::gettext("Use Perl 6 constructor syntax"),
					listener => sub { 
						#Replace first 'new Foo' with 'Foo.new' in the current line
						my $line_start = $editor->PositionFromLine( $current_line_no );
						my $line_end   = $editor->GetLineEndPosition( $current_line_no );
						my $line_text  = $editor->GetTextRange($line_start, $line_end);
						#new Point/new Point::Bar/new Point-In-Box
						$line_text =~ s/new\s+([\w\-\:\:]+)?/$1.new/;
						$editor->SetSelection( $line_start, $line_end );
						$editor->ReplaceSelection( $line_text );
					},
				};
				$comment_error_action = 1;
			
			}

			if($comment_error_action) {
				push @items, {
					text     => Wx::gettext("Comment error line"),
					listener => sub {
						#comment current error
						my $line_start = $editor->PositionFromLine( $current_line_no );
						$editor->InsertText($line_start, "#");
					},
				};
			}
			
		}
	}
	
	return @items;
}

#
# Called when the user asks for Ecliptic's quick fix dialog via CTRL-~
#
sub event_on_quick_fix {
	my ($self, $editor) = @_;

	return $self->_find_quick_fix($editor);
}

#
# Called when the user ask for the right-click menu (ALT-/ in Padre)
#
sub event_on_right_down {
	my ($self, $editor, $menu, $event ) = @_;

	my @items = $self->_find_quick_fix($editor);
	print scalar @items . "\n";
	my $main = $editor->main;
	$menu->AppendSeparator;
	for my $item (@items) {
	
		Wx::Event::EVT_MENU( 
			$main,
			$menu->Append( -1, $item->{text} ),
			$item->{listener},
		);
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
