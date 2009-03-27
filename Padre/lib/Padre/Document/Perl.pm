package Padre::Document::Perl;

use 5.008;
use strict;
use warnings;
use Carp            ();
use Encode          ();
use Params::Util    '_INSTANCE';
use YAML::Tiny      ();
use Padre::Document ();
use Padre::Util     ();

our $VERSION = '0.30';
use base 'Padre::Document';





#####################################################################
# Padre::Document::Perl Methods

# TODO watch out! These PPI methods may be VERY expensive!
# (Ballpark: Around 1 Gigahertz-second of *BLOCKING* CPU per 1000 lines)
# Check out Padre::Task::PPI and its subclasses instead!
sub ppi_get {
	my $self = shift;
	my $text = $self->text_get;
	require PPI::Document;
	PPI::Document->new( \$text );
}

sub ppi_set {
	my $self     = shift;
	my $document = _INSTANCE(shift, 'PPI::Document');
	unless ( $document ) {
		Carp::croak("Did not provide a PPI::Document");
	}

	# Serialize and overwrite the current text
	$self->text_set( $document->serialize );
}

sub ppi_find {
	my $self     = shift;
	my $document = $self->ppi_get;
	return $document->find( @_ );
}

sub ppi_find_first {
	my $self     = shift;
	my $document = $self->ppi_get;
	return $document->find_first( @_ );
}

sub ppi_transform {
	my $self      = shift;
	my $transform = _INSTANCE(shift, 'PPI::Transform');
	unless ( $transform ) {
		Carp::croak("Did not provide a PPI::Transform");
	}

	# Apply the transform to the document
	my $document = $self->ppi_get;
	unless ( $transform->document($document) ) {
		Carp::croak("Transform failed");
	}
	$self->ppi_set($document);

	return 1;
}

sub ppi_select {
	my $self     = shift;
	my $location = shift;
	if ( _INSTANCE($location, 'PPI::Element') ) {
		$location = $location->location;
	}
	my $editor   = $self->editor or return;
	my $line     = $editor->PositionFromLine( $location->[0] - 1 );
	my $start    = $line + $location->[1] - 1;
	$editor->SetSelection( $start, $start + 1 );
}


sub lexer {
	my $self = shift;
	my $config = Padre->ide->config;

	if ( $config->ppi_highlight and $self->editor->GetTextLength < $config->ppi_highlight_limit ) {
		return Wx::wxSTC_LEX_CONTAINER;
	} else {
		return $self->SUPER::lexer();
	}
}

#####################################################################
# Padre::Document GUI Integration

sub colorize {
	my $self = shift;

	# use pshangov's experimental ppi lexer only when running in development mode
	if ($ENV{PADRE_DEV}) {
		require Padre::Document::Perl::Lexer;
		Padre::Document::Perl::Lexer->colorize(@_);
		return;
	}

	$self->remove_color;

	my $editor = $self->editor;
	my $text   = $self->text_get;
	return unless $text;

	require PPI::Document;
	my $ppi_doc = PPI::Document->new( \$text );
	if (not defined $ppi_doc) {
		Wx::LogMessage( 'PPI::Document Error %s', PPI::Document->errstr );
		Wx::LogMessage( 'Original text: %s', $text );
		return;
	}

	my %colors = (
		keyword         => 4, # dark green
		structure       => 6,
		core            => 1, # red
		pragma          => 7, # purple
		'Whitespace'    => 0,
		'Structure'     => 0,

		'Number'        => 1,
		'Float'         => 1,

		'HereDoc'       => 4,
		'Data'          => 4,
		'Operator'      => 6,
		'Comment'       => 2, # it's good, it's green
		'Pod'           => 2,
		'End'           => 2,
		'Label'         => 0,
		'Word'          => 0, # stay the black
		'Quote'         => 9,
		'Single'        => 9,
		'Double'        => 9,
		'Backtick'      => 9,
		'Interpolate'   => 9,
		'QuoteLike'     => 7,
		'Regexp'        => 7,
		'Words'         => 7,
		'Readline'      => 7,
		'Match'         => 3,
		'Substitute'    => 5,
		'Transliterate' => 5,
		'Separator'     => 0,
		'Symbol'        => 0,
		'Prototype'     => 0,
		'ArrayIndex'    => 0,
		'Cast'          => 0,
		'Magic'         => 0,
		'Octal'         => 0,
		'Hex'           => 0,
		'Literal'       => 0,
		'Version'       => 0,
	);

	my @tokens = $ppi_doc->tokens;
	$ppi_doc->index_locations;
	my $first = $editor->GetFirstVisibleLine();
	my $lines = $editor->LinesOnScreen();
	#print "First $first lines $lines\n";
	foreach my $t (@tokens) {
		#print $t->content;
		my ($row, $rowchar, $col) = @{ $t->location };
#		next if $row < $first;
#		next if $row > $first + $lines;
		my $css = $self->_css_class($t);
#		if ($row > $first and $row < $first + 5) {
#			print "$row, $rowchar, ", $t->length, "  ", $t->class, "  ", $css, "  ", $t->content, "\n";
#		}
#		last if $row > 10;
		my $color = $colors{$css};
		if (not defined $color) {
			Wx::LogMessage("Missing definition for '$css'\n");
			next;
		}
		next if not $color;

		my $start  = $editor->PositionFromLine($row-1) + $rowchar-1;
		my $len = $t->length;

		$editor->StartStyling($start, $color);
		$editor->SetStyling($len, $color);
	}
}

sub _css_class {
	my ($self, $Token) = @_;
	if ( $Token->isa('PPI::Token::Word') ) {
		# There are some words we can be very confident are
		# being used as keywords
		unless ( $Token->snext_sibling and $Token->snext_sibling->content eq '=>' ) {
			if ( $Token->content =~ /^(?:sub|return)$/ ) {
				return 'keyword';
			} elsif ( $Token->content =~ /^(?:undef|shift|defined|bless)$/ ) {
				return 'core';
			}
		}
		if ( $Token->previous_sibling and $Token->previous_sibling->content eq '->' ) {
			if ( $Token->content =~ /^(?:new)$/ ) {
				return 'core';
			}
		}
		if ( $Token->parent->isa('PPI::Statement::Include') ) {
			if ( $Token->content =~ /^(?:use|no)$/ ) {
				return 'keyword';
			}
			if ( $Token->content eq $Token->parent->pragma ) {
				return 'pragma';
			}
		} elsif ( $Token->parent->isa('PPI::Statement::Variable') ) {
			if ( $Token->content =~ /^(?:my|local|our)$/ ) {
				return 'keyword';
			}
		} elsif ( $Token->parent->isa('PPI::Statement::Compond') ) {
			if ( $Token->content =~ /^(?:if|else|elsif|unless|for|foreach|while|my)$/ ) {
				return 'keyword';
			}
		} elsif ( $Token->parent->isa('PPI::Statement::Package') ) {
			if ( $Token->content eq 'package' ) {
				return 'keyword';
			}
		} elsif ( $Token->parent->isa('PPI::Statement::Scheduled') ) {
			return 'keyword';
		}
	}

	# Normal coloring
	my $css = ref $Token;
	$css =~ s/^.+:://;
	$css;
}





#####################################################################
# Padre::Document Document Analysis

my $keywords;

sub keywords {
	unless ( defined $keywords ) {
		$keywords = YAML::Tiny::LoadFile(
			Padre::Util::sharefile( 'languages', 'perl5', 'perl5.yml' )
		);
	}
	return $keywords;
}

sub get_functions {
	my $self = shift;
	my $text = $self->text_get;
	return $text =~ m/[\012\015]sub\s+(\w+(?:::\w+)*)/g;
}

sub get_function_regex {
	# This emulates qr/(?<=^|[\012\0125])sub\s$name\b/ but without
	# triggering a "Variable length lookbehind not implemented" error.
	return qr/(?:(?<=^)sub\s+$_[1]|(?<=[\012\0125])sub\s+$_[1])\b/;
}

sub get_command {
	my $self     = shift;
	my $debug    = shift;

	# Check the file name
	my $filename = $self->filename;
#	unless ( $filename and $filename =~ /\.pl$/i ) {
#		die "Only .pl files can be executed\n";
#	}

	# Run with the same Perl that launched Padre
	# TODO: get preferred Perl from configuration
	my $perl = Padre->perl_interpreter;

	my $dir = File::Basename::dirname($filename);
	chdir $dir;
	return $debug
		? qq{"$perl" -Mdiagnostics(-traceonly) "$filename"}
		: qq{"$perl" "$filename"};
}

sub pre_process {
	my $self = shift;

	if ( Padre->ide->config->editor_beginner ) {
		require Padre::Document::Perl::Beginner;
		my $b = Padre::Document::Perl::Beginner->new;
		if ($b->check( $self->text_get )) {
			return 1;
		} else {
			$self->set_errstr( $b->error );
			return;
		}
	}

	return 1;
}

# Checks the syntax of a Perl document.
# Documented in Padre::Document!
# Implemented as a task. See Padre::Task::SyntaxChecker::Perl
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
	my $args = shift;
	my $text = $self->text_get;
	unless ( defined $text and $text ne '' ) {
		return [];
	}

	# Do we really need an update?
	require Digest::MD5;
	my $md5 = Digest::MD5::md5_hex(Encode::encode_utf8($text));
	unless ( $args->{force} ) {
		if (
			defined($self->{last_syncheck_md5})
			and
			$self->{last_syncheck_md5} eq $md5
		) {
			return;
		}
	}
	$self->{last_syncheck_md5} = $md5;
	
	my $nlchar = "\n";
	if ( $self->get_newline_type eq 'WIN' ) {
		$nlchar = "\r\n";
	}
	elsif ( $self->get_newline_type eq 'MAC' ) {
		$nlchar = "\r";
	}

	require Padre::Task::SyntaxChecker::Perl;
	my %check = (
		editor   => $self->editor,
		text     => $text,
		newlines => $nlchar,
	);
	if ( exists $args->{on_finish} ) {
		$check{on_finish} = $args->{on_finish};
	}
	if ( $self->project ) {
		$check{cwd} = $self->project->root;
		$check{perl_cmd} = [ '-Ilib' ];
	}
	my $task = Padre::Task::SyntaxChecker::Perl->new( %check );
	if ( $args->{background} ) {
		# asynchroneous execution (see on_finish hook)
		$task->schedule;
		return();
	} else {
		# serial execution, returning the result
		return() if $task->prepare() =~ /^break$/;
		$task->run();
		return $task->{syntax_check};
	}
}

sub get_outline {
	my $self = shift;
	my %args = @_;

	my $text = $self->text_get;
	unless ( defined $text and $text ne '' ) {
		return [];
	}

	# Do we really need an update?
	require Digest::MD5;
	my $md5 = Digest::MD5::md5_hex(Encode::encode_utf8($text));
	unless ( $args{force} ) {
		if (
			defined($self->{last_outline_md5})
			and
			$self->{last_outline_md5} eq $md5
		) {
			return;
		}
	}
	$self->{last_outline_md5} = $md5;

	my %check = (
		editor   => $self->editor,
		text     => $text,
	);
	if ( $self->project ) {
		$check{cwd} = $self->project->root;
		$check{perl_cmd} = [ '-Ilib' ];
	}

	require Padre::Task::Outline::Perl;
	my $task = Padre::Task::Outline::Perl->new( %check );

	# asynchronous execution (see on_finish hook)
	$task->schedule;
	return;
}

sub comment_lines_str {
	return '#';
}

sub find_unmatched_brace {
	my ($self) = @_;

	# create a new object of the task class and schedule it
	Padre::Task::PPI::FindUnmatchedBrace->new(
		# for parsing
		text     => $self->text_get,
		# will be available in "finish" but not in "run"/"process_ppi"
		document => $self,
	)->schedule;

	return ();
}

# finds the start of the current symbol.
# current symbol means in the context something remotely similar
# to what PPI considers a PPI::Token::Symbol, but since we're doing
# it the manual, stupid way, this may also work within quotelikes and regexes.
sub _get_current_symbol {
	my $editor = shift;
	my $pos          = $editor->GetCurrentPos;
	my $line         = $editor->LineFromPosition($pos);
	my $line_start   = $editor->PositionFromLine($line);
	my $cursor_col   = $pos-$line_start; # TODO: let's hope this is the physical column
	my $line_end     = $editor->GetLineEndPosition($line);
	my $line_content = $editor->GetTextRange($line_start, $line_end);
	my $col          = $cursor_col;

	# find start of symbol TODO: This could be more robust, no?
	while (1) {
		if ($col == 0 or substr($line_content, $col, 1) =~ /^[^\w:\']$/) {
			last;
		}
		$col--;
	}

	if ( $col == 0 or substr($line_content, $col+1, 1) !~ /^[\w:\']$/ ) {
		return ();
	}
	return [$line+1, $col+1];
}

sub find_variable_declaration {
	my ($self) = @_;

	my $location = _get_current_symbol($self->editor);
	unless ( defined $location ) {
		Wx::MessageBox(
			Wx::gettext("Current cursor does not seem to point at a variable"),
			Wx::gettext("Check cancelled"),
			Wx::wxOK,
			Padre->ide->wx->main
		);
		return ();
	}

	# create a new object of the task class and schedule it
	Padre::Task::PPI::FindVariableDeclaration->new(
		document => $self,
		location => $location,
	)->schedule;

	return ();
}





#####################################################################
# Padre::Document Document Manipulation

sub lexical_variable_replacement {
	my ($self, $replacement) = @_;

	my $location = _get_current_symbol($self->editor);
	if (not defined $location) {
		Wx::MessageBox(
			Wx::gettext("Current cursor does not seem to point at a variable"),
			Wx::gettext("Check cancelled"),
			Wx::wxOK,
			Padre->ide->wx->main
		);
		return ();
	}
	# create a new object of the task class and schedule it
	Padre::Task::PPI::LexicalReplaceVariable->new(
		document => $self,
		location => $location,
		replacement => $replacement,
	)->schedule;

	return ();
}

sub autocomplete {
	my $self   = shift;

	my $editor = $self->editor;
	my $pos    = $editor->GetCurrentPos;
	my $line   = $editor->LineFromPosition($pos);
	my $first  = $editor->PositionFromLine($line);

	# line from beginning to current position
	my $prefix = $editor->GetTextRange($first, $pos);
	   $prefix =~ s{^.*?((\w+::)*\w+)$}{$1};
	my $last   = $editor->GetLength();
	my $text   = $editor->GetTextRange(0, $last);
	my $pre_text  = $editor->GetTextRange(0, $first+length($prefix)); 
	my $post_text = $editor->GetTextRange($first, $last); 

	my $regex;
	eval { $regex = qr{\b($prefix\w+(?:::\w+)*)\b} };
	if ($@) {
		return ("Cannot build regex for '$prefix'");
	}

	my %seen;
	my @words;
	push @words ,grep { ! $seen{$_}++ } reverse ($pre_text =~ /$regex/g);
	push @words ,grep { ! $seen{$_}++ } ($post_text =~ /$regex/g);

	if (@words > 20) {
		@words = @words[0..19];
	}

	return (length($prefix), @words);
}

sub event_on_char {
	my ( $self, $editor, $event ) = @_;
	$editor->Freeze;

	my $selection_exists = 0;
	my $text = $editor->GetSelectedText;
	if ( defined($text) && length($text) > 0 ) {
		$selection_exists = 1;
	}

	my $key = $event->GetUnicodeKey;

	if ( Padre->ide->config->autocomplete_brackets ) {
		my %table = (
			34 => 34,   # " "
			39 => 39,   # ' '
			40 => 41,   # ( )
			60 => 62,   # < >
			91 => 93,   # [ ]
			123 => 125, # { }
		);
		my $pos = $editor->GetCurrentPos;
		foreach my $code ( keys %table ) {
			if ( $key == $code ) {
				if ( $selection_exists ) {
					my $start = $editor->GetSelectionStart;
					my $end   = $editor->GetSelectionEnd;
					$editor->GotoPos($end);
					$editor->AddText( chr( $table{$code} ) );
					$editor->GotoPos($start);
				}
				else {
					my $nextChar;
					if ( $editor->GetTextLength > $pos ) {
						$nextChar = $editor->GetTextRange( $pos, $pos + 1 );
					}
					unless (
						defined($nextChar)
						&& ord($nextChar) == $table{$code}
					) {
						$editor->AddText( chr( $table{$code} ) );
						$editor->CharLeft;
						last;
					}
				}
			}
		}
	}

	$editor->Thaw;
	return;
}

1;

# Copyright 2008-2009 The Padre development team as listed in Padre.pm.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.
