package Padre::Document::LaTeX;

# ABSTRACT: LaTeX document support for Padre

use 5.008;
use strict;
use warnings;
use Carp            ();
use Padre::Document ();

our @ISA = 'Padre::Document';

sub task_functions {
	return '';
}

sub task_outline {
	return '';
}

sub task_syntax {
	return 'Padre::Document::LaTeX::Syntax';
}

sub get_command {
	my $self  = shift;

	my $arg_ref = shift || {};

	my $debug = exists $arg_ref->{debug} ? $arg_ref->{debug} : 0;
	my $trace = exists $arg_ref->{trace} ? $arg_ref->{trace} : 0;

	my $filename = $self->filename;
	my $dir = File::Basename::dirname($filename);
	chdir $dir;
	$filename = $self->get_title;
	
	my $command = "pdflatex -interaction nonstopmode -file-line-error $filename";
	warn "$command\n";
	return $command;
}

sub comment_lines_str {
	return '%'
}

my @latex_commands = qw/
	begin end
	
	DeclareMathOperator

	addtocounter appendix author
	bibliography bibliographystyle
	caption chapter cite
	date documentclass dots
	footnote
	hline href hspace
	include includegraphics insert institute item
	label
	maketitle
	newcommand newpage
	pagebreak pagestyle paragraph
	ref
	section subsection subsubsection subtitle 
	tableofcontents textbar textbf textcolor textgreater textit textless textsc
	texttt thepage title titlegraphic today
	url usepackage
	vspace

	alpha beta gamma sigma omega
	cdot frac ge hat in langle left leftarrow Leftarrow mathcal mathrm partial
	rangle right rightarrow Rightarrow rightleftarrow Rightleftarrow
	seteq substack sum text vee wedge

	bigskip DeclareOptionBeamer defbeamertemplate frame frametitle mode note
	ProcessOptionsBeamer
	setbeamercolor setbeamersize setbeamertemplate usebeamerfont usetheme
	
	fancyhead fancyfoot headheight headrulewidth footrulewidth		
/;

my @latex_environments = qw/
	align cases center document enumerate eqnarray equation figure footnotesize
	itemize Large
	math pmatrix small table tabular tiny verbatim

	algorithm algorithmic

	column columns

	beamercolorbox frame
/;

# TODO instead, determine packages available on the system
my @latex_packages = qw/
	a4wide alg algorithm2e algorithmicx algpseudocode amsfonts amsmath amsopn amssymb
	babel beamer
	cite color colortbl
	dcolumn
	fancybox fontenc
	graphics graphicx
	hyperref
	ifthen import inputenc
	lastpage latexsym listings longtable
	makeidx multicol multirow
	pgf
	tabularx times
	url
	verbatim
	xcolor xy
/;

# method copied from the PHP plugin and a adapted a bit
# TODO document
# TODO know includegraphics etc. options (see CSS completion support for ideas)
# TODO units for height, width, vspace, etc.
# TODO for bibliography, insert, include, includegraphics, usepackage: check for available files ...
sub autocomplete {
	my $self  = shift;
	my $event = shift;

	my $config    = Padre->ide->config;
	my $min_chars = $config->perl_autocomplete_min_chars; # TODO rename this config option?

	my $editor = $self->editor;
	my $pos    = $editor->GetCurrentPos;
	my $line   = $editor->LineFromPosition($pos);
	my $first  = $editor->PositionFromLine($line);

	# This function is called very often, return asap
	return if ( $pos - $first ) < ( $min_chars - 1 );

	# line from beginning to current position
	my $prefix = $editor->GetTextRange( $first, $pos );

	# Remove any ident from the beginning of the prefix
	$prefix =~ s/^[\r\t]+//;
	return if length($prefix) == 0;

	# One char may be added by the current event
	return if length($prefix) < ( $min_chars - 1 );

	# The second parameter may be a reference to the current event or the next
	# char which will be added to the editor:
	my $nextchar = '';                   # Use empty instead of undef
	if ( defined($event) and ( ref($event) eq 'Wx::KeyEvent' ) ) {
		my $key = $event->GetUnicodeKey;
		$nextchar = chr($key);
	} elsif ( defined($event) and ( !ref($event) ) ) {
		$nextchar = $event;
	}
	return if ord($nextchar) == 27;      # Close on escape
	$nextchar = '' if ord($nextchar) < 32;

	# abort ASAP
	return if $prefix !~ /\\(\w+.*)$/;
	$prefix = $1;	

	# check for environments
	if ($prefix =~ /(begin|end)(?:(\{)(\w*))?$/) { # TODO use extended regex
		my $begin_or_end = $1;
		my $add_bracket  = defined $2 ? '' : '{';
		my $env_prefix   = defined $3 ? $3 : '';

		# TODO end the currently open environment
 
		my @candidates = $begin_or_end eq 'begin'
					? map { $add_bracket . $_ . "}\n\\end{$_}" } @latex_environments  # TODO make configurable
					: map { $add_bracket . $_ . '}' }            @latex_environments;
		return $self->find_completions( $env_prefix, $nextchar, @candidates );
	}

	# check for packages
	if ($prefix =~ /usepackage(?:(\{)(\w*))?$/) {
		my $add_bracket = defined $1 ? '' : '{';
		my $use_prefix  = defined $2 ? $2 : '';
		
		my @candidates =  map { $add_bracket . $_ . '}' } @latex_packages;
		return $self->find_completions( $use_prefix, $nextchar, @candidates );		
	}

	# check for citations
	if ($prefix =~ /cite\w?(?:(\{)(\w*))?$/) {
		my $add_bracket = defined $1 ? '' : '{';
		my $cite_prefix = defined $2 ? $2 : '';
		
		# search entire document for citations
		my $text = $editor->GetText;
		my @citations = ();
		while ($text =~ /cite\{([\w:]+)\}/g) {
			push @citations, $add_bracket . $1 . '}';
		}
		
		# TODO look at the bibliography files
		return $self->find_completions( $cite_prefix, $nextchar, @citations );		
	}
	
	# check for internal references
	if ($prefix =~ /ref(?:(\{)(\w*))?$/) {
		my $add_bracket = defined $1 ? '' : '{';
		my $ref_prefix  = defined $2 ? $2 : '';
		
		# search entire document for labels and references
		my $text = $editor->GetText;
		my @references = ();
		while ($text =~ /(?:label|ref)\{([\w:]+)\}/g) {
			push @references, $add_bracket . $1 . '}';
		}
		
		return $self->find_completions( $ref_prefix, $nextchar, @references );		
	}	

	# check for commands
	return if $prefix !~ /(\w+)$/;
	$prefix = $1;	
	# TODO distinguish math mode
	# TODO check which packages are included?
	return $self->find_completions($prefix, $nextchar, '', @latex_commands);
}

# TODO find a nicer name
# TODO think about how to handle post_text and pre_text (maybe use a switch?)
# TODO move to a place where all Padre document classes can use this ...
sub find_completions {
	my $self     = shift;
	my $prefix   = shift;
	my $nextchar = shift;
	my @candidates = @_;

	my $editor = $self->editor;
	my $pos    = $editor->GetCurrentPos;
	my $line   = $editor->LineFromPosition($pos);
	my $first  = $editor->PositionFromLine($line);
	
	my $last      = $editor->GetLength();
	my $pre_text  = $editor->GetTextRange( 0, $first + length($prefix) );
	my $post_text = $editor->GetTextRange( $first, $last );

	my $regex;
	eval { $regex = qr{\b(\Q$prefix\E\w*)\b} };
	if ($@) {
		warn "Cannot build regex for '$prefix'\n";
		return;
	}
	
	my %seen;
	my @words;
	push @words, grep { $_ =~ $regex and !$seen{$_}++} @candidates;
	push @words, grep { !$seen{$_}++ } reverse( $pre_text =~ /$regex/g );
	push @words, grep { !$seen{$_}++ } ( $post_text =~ /$regex/g );

	# TODO is 20 a good limit?
	# TODO configurable?
	if ( scalar @words > 20 ) {
		@words = @words[ 0 .. 19 ];
	}

	# Suggesting the current word as the only solution doesn't help
	# anything, but your need to close the suggestions window before
	# you may press ENTER/RETURN.
	if ( ( $#words == 0 ) and ( $prefix eq $words[0] ) ) {
		return;
	}

	my $suffix = $editor->GetTextRange( $pos, $pos + 15 );
	$suffix = $1 if $suffix =~ /^(\w*)/; # Cut away any non-word chars

	# While typing within a word, the rest of the word shouldn't be
	# inserted.
	if ( defined($suffix) ) {
		for ( 0 .. $#words ) {
			$words[$_] =~ s/\Q$suffix\E$//;
		}
	} # TODO check this

	# This is the final result if there is no char which hasn't been
	# saved to the editor buffer until now
	return ( length($prefix), @words ) if !defined($nextchar);

	# Finally cut out all words which do not match the next char
	# which will be inserted into the editor (by the current event)
	my @final_words;
	for (@words) {

		# Accept everything which has prefix + next char + at least one other char
		next if !/^\Q$prefix$nextchar\E./;
		push @final_words, $_;
	}

	return ( length($prefix), @final_words );	
}


1;
