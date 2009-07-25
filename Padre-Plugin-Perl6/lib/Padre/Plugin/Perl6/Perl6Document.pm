package Padre::Plugin::Perl6::Perl6Document;

use 5.010;
use strict;
use warnings;

use Padre::Wx ();

our $VERSION = '0.55';
our @ISA     = 'Padre::Document';

# max lines to display in a calltip
my $CALLTIP_DISPLAY_COUNT = 10;


# get Perl6 (rakudo) command line for "Run script" F5 Padre menu item
sub get_command {
	my $self = shift;

	my $filename = $self->filename;
	require Padre::Plugin::Perl6::Util;
	my $perl6 = Padre::Plugin::Perl6::Util::perl6_exe();

	if ( not $perl6 ) {
		my $main = Padre->ide->wx->main;
		$main->error(
			"Either perl6 needs to be in the PATH or RAKUDO_DIR must point to the directory of the Rakudo checkout.");
		return;
	}

	return qq{"$perl6" "$filename"};
}

# Checks the syntax of a Perl document.
# Documented in Padre::Document!
# Implemented as a task. See Padre::Plugin::Perl6::Perl6SyntaxChecker
sub check_syntax {
	my $self = shift;
	my %args = @_;
	$args{background} = 0;
	return $self->_check_syntax_internals( \%args );
}

sub check_syntax_in_background {
	my $self = shift;
	my %args = @_;
	$args{background} = 1;
	return $self->_check_syntax_internals( \%args );
}

sub _check_syntax_internals {
	my $self = shift;
	my $args = shift;

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
		text          => $text,
		issues        => $self->{issues},
		( exists $args->{on_finish} ? ( on_finish => $args->{on_finish} ) : () ),
	);
	if ( $args->{background} ) {

		# asynchroneous execution (see on_finish hook)
		$task->schedule();
		return ();
	} else {

		# serial execution, returning the result
		return () if $task->prepare() =~ /^break$/;
		$task->run();
		return $task->{syntax_check};
	}
	return;
}

# In Perl 6 the best way to comment the current error reliably is
# by putting a hash and a space since #( is an embedded comment in Perl 6!
# see S02:166
sub comment_lines_str {
	return '# ';
}

#
# Guess the new line for the current document
# can return \r, \r\n, or \n
#
sub guess_newline {
	my $self = shift;

	require Padre::Util;
	my $doc_new_line_type = Padre::Util::newline_type( $self->text_get );
	my $new_line;
	if ( $doc_new_line_type eq "WIN" ) {
		$new_line = "\r\n";
	} elsif ( $doc_new_line_type eq "MAC" ) {
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
	my ( $self, $editor ) = @_;

	if ( not defined $self->{issues} ) {
		$self->{issues} = [];
	}

	my $nl              = $self->guess_newline;
	my $current_line_no = $editor->GetCurrentLine;

	my @items      = ();
	my $num_issues = scalar @{ $self->{issues} };
	foreach my $issue ( @{ $self->{issues} } ) {
		my $issue_line_no = $issue->{line} - 1;
		if ( $issue_line_no == $current_line_no ) {
			my $issue_msg = $issue->{msg};
			$issue_msg =~ s/^\s+|\s+$//g;
			if ( $issue_msg =~ /^Variable\s+(.+?)\s+is not predeclared at/i ) {

				my $var_name = $1;

				# Fixes the following:
				# 	$foo = 1;
				# into:
				# 	my $foo;
				#	$foo = 1;
				push @items, {
					text     => sprintf( Wx::gettext('Insert declaration for %s'), $var_name ),
					listener => sub {

						#Insert a variable declaration before the start of the current line
						my $line_start = $editor->PositionFromLine($current_line_no);
						my $line_end   = $editor->GetLineEndPosition($current_line_no);
						my $line_text  = $editor->GetTextRange( $line_start, $line_end );
						my $indent     = ( $line_text =~ /(^\s+)/ ) ? $1 : '';
						$line_text = "${indent}my $var_name;$nl" . $line_text;
						$editor->SetSelection( $line_start, $line_end );
						$editor->ReplaceSelection($line_text);
					},
				};

			} elsif ( $issue_msg =~ /^Undeclared routine:\s+(.+?)\s+used/i ) {

				my $routine_name = $1;

				#flow control keywords
				my @flow_control_keywords = (
					'for',    'given', 'if',   'loop', 'repeat',
					'unless', 'until', 'when', 'while',
				);
				foreach my $keyword (@flow_control_keywords) {
					if ( $keyword eq $routine_name ) {

						# Fixes the following:
						# 	if() { };
						# into:
						# 	if () { };
						push @items, {
							text     => sprintf( Wx::gettext('Insert a space after %s'), $keyword ),
							listener => sub {

								#Insert a space before brace
								my $line_start = $editor->PositionFromLine($current_line_no);
								my $line_end   = $editor->GetLineEndPosition($current_line_no);
								my $line_text  = $editor->GetTextRange( $line_start, $line_end );
								$line_text =~ s/$keyword\(/$keyword \(/;
								$editor->SetSelection( $line_start, $line_end );
								$editor->ReplaceSelection($line_text);
							},
						};

						last;
					}
				}

				# Fixes the following:
				# 	foo();
				# into:
				# 	sub foo() {
				#		#XXX-implement
				# 	}
				# 	foo();
				push @items, {
					text     => sprintf( Wx::gettext('Insert routine %s'), $routine_name ),
					listener => sub {

						#Insert an empty routine definition before the current line
						my $line_start = $editor->PositionFromLine($current_line_no);
						my $line_end   = $editor->GetLineEndPosition($current_line_no);
						my $line_text  = $editor->GetTextRange( $line_start, $line_end );
						my $indent     = ( $line_text =~ /(^\s+)/ ) ? $1 : '';
						$line_text =
							  "${indent}sub $routine_name {$nl"
							. "${indent}\t#XXX-implement$nl"
							. "${indent}}$nl"
							. $line_text;
						$editor->SetSelection( $line_start, $line_end );
						$editor->ReplaceSelection($line_text);
					},
				};

			} elsif ( $issue_msg =~ /^Obsolete use of . to concatenate strings/i ) {

				# Fixes the following:
				# 	$string = "a" . "b";
				# into:
				# 	$string = "a" ~ "b";
				push @items, {
					text     => Wx::gettext('Use ~ instead of . for string concatenation'),
					listener => sub {

						#replace first '.' with '~' in the current line
						my $line_start = $editor->PositionFromLine($current_line_no);
						my $line_end   = $editor->GetLineEndPosition($current_line_no);
						my $line_text  = $editor->GetTextRange( $line_start, $line_end );
						$line_text =~ s/\./~/;
						$editor->SetSelection( $line_start, $line_end );
						$editor->ReplaceSelection($line_text);
					},
				};

			} elsif ( $issue_msg =~ /^Obsolete use of -> to call a method/i ) {

				# Fixes the following:
				# 	P->foo;
				# into:
				# 	P.foo;
				push @items, {
					text     => Wx::gettext('Use . for method call'),
					listener => sub {

						#Replace first '->' with '.' in the current line
						my $line_start = $editor->PositionFromLine($current_line_no);
						my $line_end   = $editor->GetLineEndPosition($current_line_no);
						my $line_text  = $editor->GetTextRange( $line_start, $line_end );
						$line_text =~ s/\-\>/\./;
						$editor->SetSelection( $line_start, $line_end );
						$editor->ReplaceSelection($line_text);
					},
				};

			} elsif ( $issue_msg =~ /^Obsolete use of C\+\+ constructor syntax/i ) {

				# Fixes the following:
				# 	new Foo;
				# into:
				# 	Foo.new;
				push @items, {
					text     => Wx::gettext('Use Perl 6 constructor syntax'),
					listener => sub {

						#Replace first 'new Foo' with 'Foo.new' in the current line
						my $line_start = $editor->PositionFromLine($current_line_no);
						my $line_end   = $editor->GetLineEndPosition($current_line_no);
						my $line_text  = $editor->GetTextRange( $line_start, $line_end );

						#new Point/new Point::Bar/new Point-In-Box
						$line_text =~ s/new\s+([\w\-\:\:]+)?/$1.new/;
						$editor->SetSelection( $line_start, $line_end );
						$editor->ReplaceSelection($line_text);
					},
				};

			} elsif ( $issue_msg =~ /^Obsolete use of C-style "for \(;;\)" loop/i ) {

				# Fixes the following:
				# 	for(;;) { };
				# into:
				# 	loop(;;) { };
				push @items, {
					text     => Wx::gettext('Use loop (;;) for looping'),
					listener => sub {

						#Replace first 'for (;;)' with 'loop (;;)' in the current line
						my $line_start = $editor->PositionFromLine($current_line_no);
						my $line_end   = $editor->GetLineEndPosition($current_line_no);
						my $line_text  = $editor->GetTextRange( $line_start, $line_end );
						$line_text =~ s/for\s+\(/loop (/;
						$editor->SetSelection( $line_start, $line_end );
						$editor->ReplaceSelection($line_text);
					},
				};

			} elsif ( $issue_msg =~ /^Obsolete use of \[-1\] subscript to access final element/i ) {

				# Fixes the following:
				# 	[-1];
				# into:
				# 	[*-1];
				push @items, {
					text     => Wx::gettext('Use [*-1] to access final element'),
					listener => sub {

						#Replace first '[-1]' with '[*-1]' in the current line
						my $line_start = $editor->PositionFromLine($current_line_no);
						my $line_end   = $editor->GetLineEndPosition($current_line_no);
						my $line_text  = $editor->GetTextRange( $line_start, $line_end );
						$line_text =~ s/\[\s*-1\s*\]/[*-1]/;
						$editor->SetSelection( $line_start, $line_end );
						$editor->ReplaceSelection($line_text);
					},
				};

			} elsif ( $issue_msg =~ /^Obsolete use of rand\(N\)/i ) {

				# Fixes the following:
				# 	rand(10);
				# into:
				# 	10.pick;
				push @items, {
					text     => Wx::gettext('Use N.pick for a random number'),
					listener => sub {

						#Replace rand(N) with N.pick' in the current line
						my $line_start = $editor->PositionFromLine($current_line_no);
						my $line_end   = $editor->GetLineEndPosition($current_line_no);
						my $line_text  = $editor->GetTextRange( $line_start, $line_end );
						$line_text =~ s/rand\s*\(\s*(.+?)\s*\)/$1.pick/;
						$editor->SetSelection( $line_start, $line_end );
						$editor->ReplaceSelection($line_text);
					},
				};

				# Fixes the following:
				# 	rand(10);
				# into:
				# 	(1..10).pick;
				push @items, {
					text     => Wx::gettext('Use (1..N).pick for a random number'),
					listener => sub {

						#Replace rand(N) with (1..N).pick' in the current line
						my $line_start = $editor->PositionFromLine($current_line_no);
						my $line_end   = $editor->GetLineEndPosition($current_line_no);
						my $line_text  = $editor->GetTextRange( $line_start, $line_end );
						$line_text =~ s/rand\s*\(\s*(.+?)\s*\)/(1..$1).pick/;
						$editor->SetSelection( $line_start, $line_end );
						$editor->ReplaceSelection($line_text);
					},
				};

			} elsif ( $issue_msg =~ /^Please use \.\.\* for indefinite range/i ) {

				# Fixes the following:
				# 	[1..];
				# into:
				# 	[1..*];
				push @items, {
					text     => Wx::gettext('Use [N..*] for indefinite range'),
					listener => sub {

						#Replace first '[1..]' with '[1..*]' in the current line
						my $line_start = $editor->PositionFromLine($current_line_no);
						my $line_end   = $editor->GetLineEndPosition($current_line_no);
						my $line_text  = $editor->GetTextRange( $line_start, $line_end );
						$line_text =~ s/\[\s*(.+?)\.\.\s*\]/\[$1..*\]/;
						$editor->SetSelection( $line_start, $line_end );
						$editor->ReplaceSelection($line_text);
					},
				};

			} elsif ( $issue_msg =~ /^Please use \!\! rather than \:\:/i ) {

				# Fixes the following:
				# 	1 == 2 ?? 1 :: 2;
				# into:
				# 	1 == 2 ?? 1 !! 2;
				push @items, {
					text     => Wx::gettext('Use !! for conditional operator'),
					listener => sub {

						#Replace first '!!' with '::' in the current line
						my $line_start = $editor->PositionFromLine($current_line_no);
						my $line_end   = $editor->GetLineEndPosition($current_line_no);
						my $line_text  = $editor->GetTextRange( $line_start, $line_end );
						$line_text =~ s/\:\:/!!/;
						$editor->SetSelection( $line_start, $line_end );
						$editor->ReplaceSelection($line_text);
					},
				};

			} elsif ( $issue_msg =~ /^Precedence too loose within \?\?\!\!/i ) {

				# Fixes errors like:
				# 	42 ?? 1,2,3 Z 4,5,6 !! 1,2,3 X 4,5,6;
				# into:
				# 	42 ?? (1,2,3 Z 4,5,6) !! 1,2,3 X 4,5,6;
				push @items, {
					text     => Wx::gettext('Use ?? (...) !! to avoid precedence bugs'),
					listener => sub {

						#Replace '?? ... !!' with '?? (...) !!' in the current line
						my $line_start = $editor->PositionFromLine($current_line_no);
						my $line_end   = $editor->GetLineEndPosition($current_line_no);
						my $line_text  = $editor->GetTextRange( $line_start, $line_end );

						#XXX- handle multiple lines...
						$line_text =~ s/\?\?(.+?)\!\!/??($1)!!/;
						$editor->SetSelection( $line_start, $line_end );
						$editor->ReplaceSelection($line_text);
					},
				};

			} elsif ( $issue_msg =~ /^Obsolete use of \?\: for the conditional operator/i ) {

				# Fixes the following:
				# 	(1 == 1) ? 1 : 2
				# into:
				# 	(1 == 1) ?? 1 !! 2
				push @items, {
					text     => Wx::gettext('Use ?? !! for the conditional operator'),
					listener => sub {

						#Replace first '? ... :' with '?? ... !!' in the current line
						my $line_start = $editor->PositionFromLine($current_line_no);
						my $line_end   = $editor->GetLineEndPosition($current_line_no);
						my $line_text  = $editor->GetTextRange( $line_start, $line_end );
						$line_text =~ s/\?\s*(.+?)\s*\:/?? $1 !!/;
						$editor->SetSelection( $line_start, $line_end );
						$editor->ReplaceSelection($line_text);
					},
				};

			} elsif ( $issue_msg =~ /^Possible obsolete use of \.\= as append operator/i ) {

				# Fixes the following:
				# 	$string .= "a";
				# into:
				# 	$string ~= "a";
				push @items, {
					text     => Wx::gettext('Use ~= for string concatenation'),
					listener => sub {

						#Replace first '=.' with '=~' in the current line
						my $line_start = $editor->PositionFromLine($current_line_no);
						my $line_end   = $editor->GetLineEndPosition($current_line_no);
						my $line_text  = $editor->GetTextRange( $line_start, $line_end );
						$line_text =~ s/\.\=/~=/;
						$editor->SetSelection( $line_start, $line_end );
						$editor->ReplaceSelection($line_text);
					},
				};

			} elsif ( $issue_msg =~ /^Obsolete use of \=\~ to do pattern matching/i ) {

				# Fixes the following:
				# 	$string =~ /abc/;
				# into:
				# 	$string ~~ /abc/;
				push @items, {
					text     => Wx::gettext('Use ~~ for pattern matching'),
					listener => sub {

						#Replace first '=.' with '=~' in the current line
						my $line_start = $editor->PositionFromLine($current_line_no);
						my $line_end   = $editor->GetLineEndPosition($current_line_no);
						my $line_text  = $editor->GetTextRange( $line_start, $line_end );
						$line_text =~ s/\=\~/~~/;
						$editor->SetSelection( $line_start, $line_end );
						$editor->ReplaceSelection($line_text);
					},
				};

			} elsif ( $issue_msg =~ /^Obsolete use of \!\~ to do negated pattern matching/i ) {

				# Fixes the following:
				# 	$string !~ /abc/;
				# into:
				# 	$string !~~ /abc/;
				push @items, {
					text     => Wx::gettext('Use !~~ for negated pattern matching'),
					listener => sub {

						#Replace first '!~' with '!~~' in the current line
						my $line_start = $editor->PositionFromLine($current_line_no);
						my $line_end   = $editor->GetLineEndPosition($current_line_no);
						my $line_text  = $editor->GetTextRange( $line_start, $line_end );
						$line_text =~ s/\!\~/!~~/;
						$editor->SetSelection( $line_start, $line_end );
						$editor->ReplaceSelection($line_text);
					},
				};

			} elsif ( $issue_msg =~ /^Obsolete use of >> to do right shift/i ) {

				# Fixes the following:
				# 	2 >> 1;
				# into:
				# 	2 +> 1;
				push @items, {
					text     => Wx::gettext('Use +> for numeric right shift'),
					listener => sub {

						#Replace first '>>' with '+>' in the current line
						my $line_start = $editor->PositionFromLine($current_line_no);
						my $line_end   = $editor->GetLineEndPosition($current_line_no);
						my $line_text  = $editor->GetTextRange( $line_start, $line_end );
						$line_text =~ s/\>\>/+>/;
						$editor->SetSelection( $line_start, $line_end );
						$editor->ReplaceSelection($line_text);
					},
				};

				# Fixes the following:
				# 	100 >> 1;
				# into:
				# 	100 ~> 1;
				push @items, {
					text     => Wx::gettext('Use ~> for string right shift'),
					listener => sub {

						#Replace first '>>' with '~>' in the current line
						my $line_start = $editor->PositionFromLine($current_line_no);
						my $line_end   = $editor->GetLineEndPosition($current_line_no);
						my $line_text  = $editor->GetTextRange( $line_start, $line_end );
						$line_text =~ s/\>\>/~>/;
						$editor->SetSelection( $line_start, $line_end );
						$editor->ReplaceSelection($line_text);
					},
				};
			} elsif ( $issue_msg =~ /^Obsolete use of << to do left shift/i ) {

				# Fixes the following:
				# 	2 << 1;
				# into:
				# 	2 +< 1;
				push @items, {
					text     => Wx::gettext('Use +< for numeric left shift'),
					listener => sub {

						#Replace first '<<' with '+<' in the current line
						my $line_start = $editor->PositionFromLine($current_line_no);
						my $line_end   = $editor->GetLineEndPosition($current_line_no);
						my $line_text  = $editor->GetTextRange( $line_start, $line_end );
						$line_text =~ s/\<\</+</;
						$editor->SetSelection( $line_start, $line_end );
						$editor->ReplaceSelection($line_text);
					},
				};

				# Fixes the following:
				# 	100 << 1;
				# into:
				# 	100 ~< 1;
				push @items, {
					text     => Wx::gettext('Use ~< for string left shift'),
					listener => sub {

						#Replace first '<<' with '~<' in the current line
						my $line_start = $editor->PositionFromLine($current_line_no);
						my $line_end   = $editor->GetLineEndPosition($current_line_no);
						my $line_text  = $editor->GetTextRange( $line_start, $line_end );
						$line_text =~ s/\<\</~</;
						$editor->SetSelection( $line_start, $line_end );
						$editor->ReplaceSelection($line_text);
					},
				};

			} elsif ( $issue_msg =~ /^Obsolete use of \$\@ variable as eval error/i ) {

				# Fixes the following:
				# 	$@;
				# into:
				# 	$!;
				push @items, {
					text     => Wx::gettext('Use $! for eval errors'),
					listener => sub {

						#Replace first '$@' with '$!' in the current line
						my $line_start = $editor->PositionFromLine($current_line_no);
						my $line_end   = $editor->GetLineEndPosition($current_line_no);
						my $line_text  = $editor->GetTextRange( $line_start, $line_end );
						$line_text =~ s/\$\@/\$!/;
						$editor->SetSelection( $line_start, $line_end );
						$editor->ReplaceSelection($line_text);
					},
				};

			} elsif ( $issue_msg =~ /^Obsolete use of \$\] variable/i ) {

				# Fixes the following:
				# 	$];
				# into:
				# 	$::PERL_VERSION;
				push @items, {
					text     => Wx::gettext('Use $::PERL_VERSION'),
					listener => sub {

						#Replace first '$]' with '$::PERL_VERSION' in the current line
						my $line_start = $editor->PositionFromLine($current_line_no);
						my $line_end   = $editor->GetLineEndPosition($current_line_no);
						my $line_text  = $editor->GetTextRange( $line_start, $line_end );
						$line_text =~ s/\$\]/\$::PERL_VERSION/;
						$editor->SetSelection( $line_start, $line_end );
						$editor->ReplaceSelection($line_text);
					},
				};

			}

		}

	}

	if ($num_issues) {

		# add "comment error line" as the last resort to solving an issue
		foreach my $issue ( @{ $self->{issues} } ) {
			my $issue_line_no = $issue->{line} - 1;
			if ( $issue_line_no == $current_line_no ) {

				# Fixes the following:
				# 	some_weird_error();
				# into:
				# 	# some_weird_error();
				push @items, {
					text     => Wx::gettext('Comment error line'),
					listener => sub {

						# comment current error by putting a hash and a space
						# since #( is an embedded comment in Perl 6! see S02:166
						my $line_start = $editor->PositionFromLine($current_line_no);
						my $line_end   = $editor->GetLineEndPosition($current_line_no);
						my $line_text  = $editor->GetTextRange( $line_start, $line_end );
						$line_text = "# ${line_text}";
						$editor->SetSelection( $line_start, $line_end );
						$editor->ReplaceSelection($line_text);
					},
				};
				last;
			}
		}

	} else {

		# No issues; let us provide a some helpful quick fixes
		my $selected_text = $editor->GetSelectedText;
		if ( $selected_text && $selected_text =~ /[\n\r]/ ) {

			# Fixes the following:
			# 	faulty_code();
			# into:
			# 	try {
			#		faulty_code();
			#
			#		CATCH {
			#			warn "oops: $!";
			#		}
			#	}

			push @items, {
				text     => Wx::gettext('Surround with try { ... }'),
				listener => sub {

					# Surround the 'selection' with a try { 'selection'  CATCH { } }
					my $line_start =
						$editor->PositionFromLine( $editor->LineFromPosition( $editor->GetSelectionStart ) );
					my $line_end = $editor->PositionFromLine( $editor->LineFromPosition( $editor->GetSelectionEnd ) );

					my $indent = ( $selected_text =~ /(^\s+)/ ) ? $1 : '';
					$selected_text =~ s/^/\t/gm;
					my $line_text =
						  "${indent}try {$nl"
						. "$selected_text$nl"
						. "${indent}\tCATCH {$nl"
						. "${indent}\t\twarn \"oops: \$!\";$nl"
						. "${indent}\t}$nl"
						. "${indent}}$nl";
					$editor->SetSelection( $line_start, $line_end );
					$editor->ReplaceSelection($line_text);
				},
			};

		}

		# Not really a fix but a helper:
		# 	Converts POD6 to XHTML
		push @items, {
			text     => Wx::gettext('Convert POD6 to XHTML'),
			listener => sub {

				# Convert POD6 to XHTML using App::Grok
				my $text = $self->text_get;
				return if not defined $text;

				require File::Temp;
				my $tmp_input = File::Temp->new( SUFFIX => '.p6' );
				binmode( $tmp_input, ":utf8" );
				print $tmp_input $text;
				close $tmp_input or warn "cannot close $tmp_input\n";

				my $main = $editor->main;
				eval {
					require App::Grok;
					my $grok = App::Grok->new;
					my $grok_text = $grok->render_target( $tmp_input->filename, 'xhtml' );

					# create a temporary HTML file
					my $tmp_output = File::Temp->new( SUFFIX => '.html' );
					$tmp_output->unlink_on_destroy(0);
					print $tmp_output $grok_text;
					my $filename = $tmp_output->filename;
					close $tmp_output or warn "Could not close $filename";

					# try to open the HTML file
					$main->setup_editor($filename);

					# launch the HTML file in your default browser
					require URI::file;
					my $file_url = URI::file->new($filename);
					Wx::LaunchDefaultBrowser($file_url);
				};
				if ($@) {
					Wx::MessageBox(
						Wx::gettext('Operation failed!'),
						Wx::gettext('Error'),
						Wx::wxOK,
						$main,
					);
				}
			},
		};

		# Not really a fix but a helper:
		# 	Converts POD6 to Text
		push @items, {
			text     => Wx::gettext('Convert POD6 to Text'),
			listener => sub {

				# Convert POD6 to Text using App::Grok
				my $text = $self->text_get;
				return if not defined $text;

				require File::Temp;
				my $tmp_input = File::Temp->new( SUFFIX => '.p6' );
				binmode( $tmp_input, ":utf8" );
				print $tmp_input $text;
				close $tmp_input or warn "cannot close $tmp_input\n";

				my $main = $editor->main;
				eval {
					require App::Grok;
					my $grok = App::Grok->new;
					my $grok_text = $grok->render_target( $tmp_input->filename, 'text' );

					# create a temporary text file
					my $tmp_output = File::Temp->new( SUFFIX => '.txt' );
					$tmp_output->unlink_on_destroy(0);
					print $tmp_output $grok_text;
					my $filename = $tmp_output->filename;
					close $tmp_output or warn "Could not close $filename";

					# try to open the text file
					$main->setup_editor($filename);
				};
				if ($@) {
					Wx::MessageBox(
						Wx::gettext('Operation failed!'),
						Wx::gettext('Error'),
						Wx::wxOK,
						$main,
					);
				}
			},
		};
	}

	return @items;
}

#
# Called when the user asks for Ecliptic's quick fix dialog via CTRL-~
#
sub event_on_quick_fix {
	my ( $self, $editor ) = @_;

	return $self->_find_quick_fix($editor);
}

#
# Called when the user ask for the right-click menu (ALT-/ in Padre)
#
sub event_on_right_down {
	my ( $self, $editor, $menu, $event ) = @_;

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

	if ( not defined $tokens ) {
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

__END__

=head1 AUTHOR

Ahmad M. Zawawi C<< <ahmad.zawawi at gmail.com> >>

Gabor Szabo L<http://szabgab.com/>

=head1 COPYRIGHT AND LICENSE

Copyright 2008-2009 Padre Developers as in Perl6.pm

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl 5 itself.
