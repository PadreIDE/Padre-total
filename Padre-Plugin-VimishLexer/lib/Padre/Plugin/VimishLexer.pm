package Padre::Plugin::VimishLexer;
use strict;
use warnings;
use 5.008;

our $VERSION = '0.01';

use Padre::Wx ();
use Padre::Current;
use IO::Scalar;
use List::Util qw(first);
use Data::Dumper qw(Dumper);
use Clone qw(clone);

use base 'Padre::Plugin';

=head1 NAME

Padre::Plugin::VimishLexer - Using the Vimish syntax highlighter

=head1 SYNOPSIS

This plugin provides an interface to the L<Syntax::Highligh::Vimish>
which implements syntax highlighting rules similar to those of the vim editor.

Currently the plugin only implements Perl 5 highlighting.

Once this plug-in is installed the user can switch the highlilghting of all 
Perl 5 files to use this highlighter via the Preferences menu
of L<Padre>.


=head1 LIMITATION

This module is still pretty buggy.

=head1 POSITIONING IN SCINTILLA

This is added here for documentation purposes while in development mode.

  GetTextLength:  number of characters
  GetLineCount:   number of lines
  LineLength:     number of characters in the current line (inclues "\n" and "\r")


  GetCurrentPos:  position:
                - the position of 1st character is 0
                - the position of the last character is GetTextLength - 1
                - the last position in the file, however, is GetTextLength

  PositionFromLine: position of first charcter in line (positions and lines start from 0)


  =================== LINES ===================

  GetCurrentLine:     line number (first line is 0)

  GetLineEndPosition: the position *after* the last character in the line, equal to LineLength

  LineFromPosition:   line number (first line is 0)
                    - the line containing the current position
                    - LineFromPosition(GetLineEndPosition(x)) = x + 1, 

  LinesOnScreen:      total number of lines on screen, regardless of whether they have text or not


  =================== TEXT RETRIEVAL ===================

  GetCharAt: character at specified position. GetCharAt(last position in file) returns undef()
  GetTextRange(x,y): characters starting from GetCharAt(x) and ending at GetCharAt(y-1)


  =================== STYLING ===================

  GetEndStyled: the index *after* the last character that has styling
              - returns GetTextLength if everything is styled

  EVT_STC_STYLENEEDED(start_pos, end_pos):
          - start_pos is the position of the first character that needs styling
          - end_pos is the position *after* the last character that needs styling

  StartStyling(start_pos) - position of first character to style
  SetStyling(length) - number of characters to style
  GetEndStyled = start_pos + length

=head1 COPYRIGHT

Copyright 2009 Peter Shangov. L<http://www.mechanicalrevolution.com/>

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl 5 itself.

=cut

########################################################
### FUNCTIONS REQUIRED BY THE PADRE PLUGIN INTERFACE ###
########################################################

sub padre_interfaces {
	return 'Padre::Plugin' => 0.41;
}

sub plugin_name {
	'Vimish Lexer';
}


sub menu_plugins_simple {
	my $self = shift;
	return $self->plugin_name => [
		'About' => sub { $self->about },
	];
}

sub provided_highlighters { 
	return (
		['Padre::Plugin::VimishLexer', 'Vimish Lexer', 'Using the Vimish Lexer'],
	);
}

sub highlighting_mime_types {
	return (
		'Padre::Plugin::VimishLexer' => ['application/x-perl'],
	);
}

sub about {
	my ($main) = @_;

	my $about = Wx::AboutDialogInfo->new;
	$about->SetName(__PACKAGE__);
	$about->SetDescription("Trying to use the Vimish lexer for syntax highlighting\n" );
	$about->SetVersion($VERSION);
	Wx::AboutBox($about);
	return;
}

# TODO shall we create a module for each mime-type and register it as a highlighter
# or is our dispatching ok?
# Shall we create a module called Pudre::Plugin::Kate::Colorize that will do the dispatching ?
# now this is the mapping to the Kate highlighter engine
my %d = (
	'application/x-perl' => 'Perl',
);

################################
### DEFINE THE PARSING RULES ###
################################

# All this stuff will ultimately go to a configuration file

my @keywords = qw( 
	if elsif else unless while for foreach do continue until defined undef
	and or not bless ref my local our sub package use shift
);
@keywords = map { $_ . '\b'} @keywords;
my $keywords_re = "^(" . join("|", @keywords, ) . ")";

my @define = (
	{ type => 'range',    name => 'pod',     start => qr(^=[a-z]), end => qr(=cut\b), start_first => 1, end_first => 1},
	{ type => 'range',    name => 'string',  start => qr(^"), end => qr(") },
	{ type => 'range',    name => 'string',  start => qr(^'), end => qr(') },
	{ type => 'match',    name => 'comment', pattern => qr(^#.*$) },
	{ type => 'literal',  name => 'keyword', pattern => $keywords_re },
);

##################################
### THE MAIN COLORIZE FUNCTION ###
##################################

sub colorize {
	# colorize() is called as a class method
	my $class = shift;
	
	# colorize() is invoked every time a ON_STYLENEEDED event occurs
	# it receies two parameters - the start and end position of the section
	# of the docment that needs styling
	my ( $start_pos, $end_pos ) = @_;
	
	debug("\n=== COLORIZE($start_pos, $end_pos) CALLED! ===\n");
	db_pos("\n=== COLORIZE($start_pos, $end_pos) CALLED! ===\n");

	# Padre may sometimes call colorize() without arguments when it needs
	# the whole document styled
	$start_pos = 0 unless defined $start_pos;

	# both $start_pos and $end_pos may be modified, but we will
	# need a copy of the original $end_pos below
	my $original_stc_end_pos = $end_pos;

	my $doc    = Padre::Current->document;
	my $editor = $doc->editor;
	my $matches = $doc->{__VimishLexer}{matches};

	### DETERMINE THE $start_pos THAT WE WILL PASS TO parse_code() ###
	
	# db_pos("\n=== COLORIZE ===\n");

	db_pos("GetTextLength: "      . $editor->GetTextLength         . "\n");
	db_pos("GetCurrentLine: "     . $editor->GetCurrentLine        . "\n");
	db_pos("GetLineCount: "       . $editor->GetLineCount          . "\n");
	db_pos("LineLength: "         . $editor->LineLength(0)         . "\n");
	db_pos("LinesOnScreen: "      . $editor->LinesOnScreen         . "\n");
	db_pos("GetCurrentPos: "      . $editor->GetCurrentPos         . "\n");
	db_pos("GetLineEndPosition: " . $editor->GetLineEndPosition(0) . "\n");
	db_pos("LineFromPosition(0): " . $editor->LineFromPosition(0)  . "\n");
	db_pos("PositionFromLine(0): " . $editor->PositionFromLine(0)  . "\n");
	db_pos("GetCharAt(4): "       . $editor->GetCharAt(4)          . "\n");
	db_pos("GetTextRange(0,4): "  . $editor->GetTextRange(0,4)     . "\n");
	db_pos("GetEndStyled: "       . $editor->GetEndStyled          . "\n");
	
	$editor->StartStyling( 2, 1 );
	$editor->SetStyling( 1, 1 );
	
	db_pos("GetEndStyled: "       . $editor->GetEndStyled          . "\n");

	return;

	# move start position to begginning of line
	my $start_pos_line = $editor->LineFromPosition($start_pos);
	# is the "if" really needed?
	$start_pos = $editor->PositionFromLine($start_pos_line) if $start_pos;
	
	### DETERMINE THE $end_pos THAT WE WILL PASS TO parse_code() ###

	# move end position to end of the 50-th line after the 
	# last visible line on the screen, or to the end of the file
	# if nearer
	my $last_visible_line = $editor->GetFirstVisibleLine + $editor->LinesOnScreen;
	my $last_visible_line_plus_50 = $last_visible_line + 50;
	my $total_line_count = $editor->GetLineCount;
	
	$last_visible_line_plus_50 > $total_line_count 
		? $end_pos = $editor->GetLineEndPosition( $total_line_count - 1 )
		: $end_pos = $editor->GetLineEndPosition( $last_visible_line_plus_50 - 1 );
	
	# why??
	$end_pos++;

	
	warn $end_pos;
	my $full_text = $doc->text_get;
	### PARSE ###
	$matches = parse_code($full_text, $start_pos, $end_pos, $matches);

	### APPLY THE COLORS ###

	# clear the color from the start of the segment on
	clear_style($start_pos, $editor->GetLength);
	# $doc->remove_color;

	#print Dumper $matches;
	
	# colorize the segment
	foreach my $m (@$matches) {
		$editor->StartStyling( $m->{start}, $m->{color} );
		$editor->SetStyling( $m->{length}, $m->{color} );	

		debug( $m->{type} . ":"  . $m->{start} . ":" . $m->{length} 
		      . ":" . substr($full_text, $m->{start}, $m->{length}) . "\n" );
	}

	$doc->{__VimishLexer}{matches} = $matches;
	

}


#############################
### PARSE A PIECE OF CODE ###
#############################

# Returns nothing, it just updates @matches
# Called by: colorize()

sub parse_code {
	my ($text, $start_pos, $end_pos, $matches) = @_;

	# can we do away with $start_pos altogether?
	my $current_position = $start_pos;

	# check if start position is within a range
	# $current_range - stores the current range object if a range has started but not ended yet
	(my $current_range, $matches) = get_range_at_pos($start_pos, $matches);
	$current_range = $$current_range if $$current_range;
	db_match(Dumper $current_range);
	#debug( "CURREN RANGE: $$current_range\n" );

	my $text_to_parse = substr($text, $start_pos, $end_pos - $start_pos + 1);
	my $code = IO::Scalar->new(\$text_to_parse);

	# $line_start - true if we are at the start of a line, false otherwise
	my $line_start;

	debug( "TEXT TO PARSE: $text_to_parse\n" );

	while ( defined( my $line = $code->getline ) ) {
		# make sure the parser knows that we are starting to parse a new line
		$line_start = 1;

		### DEBUG ###
		debug( "LINE " . Padre::Current->document->editor->LineFromPosition($current_position) . " ===>\n" );
		#debug( "TEXT: $text\n" );
		
		# debug( "CURRENT RANGE: " . $$current_range->{name} . "\n" ) if $$current_range;
		
		parse_line($line, \$current_position, $current_range, $matches);

		# update the current position to the end of the line we just parsed 
		# requied because of space and newline characters at the end of the lines
		$current_position = $code->tell + $start_pos;
	}

	#debug("BEFORE " . Dumper $matches);
	# if after we finished parsing $current_range is defined,
	# automatically close the range
	if ($$current_range->{name}) {
		#print Dumper $current_range;
		add_match(0, $$current_range->{name}, "", $$current_range->{start_pos}, \$current_position, $matches, $current_range);
		debug( "range auto end!\n" );
	}

	# make sure that if we are the end of the file the last character is colorized,
	# otherwise Scintilla will keep firing an ON_STYLENEEDED event every time the
	# last line is visible
	my $last_match = $matches->[-1];
	# in the beginning of a new file we may not have any matches yet
	if ($last_match) {
		my $last_match_end = $last_match->{start} + $last_match->{length};
		# my $total_chars = length($text_to_parse);
		debug( "END POS: $end_pos, LAST MATCH END: $last_match_end\n" );
		if ( $end_pos > $last_match_end ) {
			add_match($end_pos - $last_match_end, "plain", undef, undef, \$current_position, $matches);
		}
	} else {
		add_match($end_pos - $start_pos + 1, "plain", undef, undef, \$current_position, $matches);
	}
	debug("MATCHES: " . Dumper $matches);
	return $matches;
}

###########################
### PARSE A SINGLE LINE ###
###########################

# Returns nothing, it just updates @matches
# Called by: parse_code()

sub parse_line {
	# get the name of the invoking sub
	my ($line, $current_position, $current_range, $matches) = @_;
	$current_position = $$current_position;

	# get the name of the invoking sub
	my $caller = (caller(1))[3];
	$caller =~ s/^.*::(\w+)$/$1/;
	# debug("PARSE_LINE($current_position) CALLED BY $caller\n");
	
	# if parse_line() has recursively called itself, then we
	# are not at the start of a line
	my $line_start = 1 unless (
		   $caller eq "parse_line" 
		|| $caller eq "add_match"
	);
	#debug("LINE START: " . ( $line_start ? 1 : 0 ) . "\n");

	# there are no interesting sybols in the line
	# don't bother updating $current_position, parse_code()
	# takes care of that
	if ( $line !~ /\S+/ ) {
		return;
	}

	### DEBUG ###
	debug( "POS: $current_position, LINE: $line\n" );

	# the bulk of the parsing takes place here
	if (!$$current_range->{name}) {
		foreach my $rule (@define) {
			next if $rule->{start_first} and !$line_start;

			if ( $rule->{type} eq 'range' ) {
				if ( $line =~ $rule->{start} ) {
					# $offset contains the number of characters matched 
					# by the $rule->{start} regex
					my $offset = $+[0];
					
					# set $current_range
					$$current_range = $rule;
					$$current_range->{start_pos} = $current_position;
					
					# continue parsing
					#debug( "OFFSET: $offset\n");
					debug( "range start found!\n" );
					$current_position += $offset;
					undef $line_start;
					my $remaining = substr($line, $offset);
					parse_line($remaining, \$current_position, $current_range, $matches) if $remaining;
					
					return;
				}
			} elsif ( $rule->{type} eq 'match' ) {
				if ( $line =~ $rule->{pattern} ) {
					debug( "match found!\n" );
					add_match($+[0], $rule->{name}, $line, undef, \$current_position, $matches);
					return;
				}
			} elsif ( $rule->{type} eq 'literal' ) {
				if ( $line =~ $rule->{pattern} ) {
					debug( "keyword found!\n" );
					add_match($+[0], "keyword", $line, undef, \$current_position, $matches);	
					return;
				}
			}
		}
		# we have found nothing, move on
		debug( "nothing found!\n" );
		
		# if a some keyword has started and has not matched, delete till the end of it;
		# don't do substr if we have already deleted stuff
		my $modified_chars = 0;
		$modified_chars += length $1 if $line =~ s/^(((::)*\w+)+)//;
		$modified_chars += length $1 if $line =~ s/^(\s+)//;
		
		# if there is still something in $line after the substitution above
		if ($line) {
			my $remaining;
			
			if ($modified_chars) {
				# if we removed any characters above,
				# just pass the remaining string
				$remaining = $line;
				$current_position += $modified_chars;
				#debug( "Modified chars: $modified_chars\n" );
			} else { 
				# else, remove 1 character and continue parsing
				$current_position++;
				$remaining = substr($line, 1); 
			}
			
			# continue parsing
			undef $line_start;
			parse_line($remaining, \$current_position, $current_range, $matches);
		}
	}
	# if we are inside a range, try to find its end
	else
	{ 
		debug( "INSIDE RANGE " . $$current_range->{name} . "\n" );
		# $current_position is updated by parse_code()
		return if $$current_range->{end_first} and !$line_start;
		
		# do we have a range end?
		if ( $line =~ $$current_range->{end} ) 
		{
			add_match($+[0], $$current_range->{name}, $line, $$current_range->{start_pos}, \$current_position, $matches, $current_range);

			# clear the current range variable
			undef $$current_range;
			debug( "range end found!\n" );
					
			return;
		} 
		# we are inside a range, and it does not end on this line,
		# there is nothing interesting to do
		else
		{
			# does this need to be here?
			$current_position += length($line);
			return;
		}
	}
}

sub add_match {
	my ($length, $type, $line, $start_pos, $current_position, $matches, $current_range) = @_;
	$current_position = $$current_position;

	my $offset = 0;
	
	if ($start_pos) {
		#debug( "Length: $length, Line: $line, Start: $start_pos, Current: $current_position\n" );
		$offset = $current_position - $start_pos;
	} else {
		if ($type eq "plain") {
			$start_pos = $current_position - $length;
		} else {
			$start_pos = $current_position;
		}
	}

	my $remaining = substr($line, $length) if $line;

	# update the global current position
	$current_position += $length unless $type eq "range";

	# colorize the empty space, if any
	my $last_match = $matches->[-1];
	if ($last_match) {
		if ($type ne "plain" && ( $start_pos > ( $last_match->{start} +  $last_match->{length}) ) ) {
			push @$matches, { 
				start  => $last_match->{start} +  $last_match->{length},
				length => $start_pos - ( $last_match->{start} +  $last_match->{length} ),
				color  => class_to_color('plain'),
				type   => 'plain',
				range  => undef,
			};	
		} elsif ($type eq "plain" && ( $start_pos > ( $last_match->{start} +  $last_match->{length}) ) ) {
			warn "kaboom!";
			$last_match->{length} = $start_pos - $last_match->{start};
		}
	} elsif ( $start_pos > 0 ) {
		push @$matches, { 
			start  => 0,
			length => $start_pos,
			color  => class_to_color('plain'),
			type   => 'plain',
			range  => undef,
		};
	}
	
	push @$matches, { 
		start  => $start_pos,
		length => $length + $offset,
		color  => class_to_color($type),
		type   => $type,
		range  => clone($current_range),
	};

	#print Dumper $current_range if $current_range;

	# parse the remainder of the line
	parse_line($remaining, \$current_position, $current_range, $matches) if $remaining;
}

#########################
### UTILITY FUNCTIONS ###
#########################

sub class_to_color {
	my $css  = shift;
	my %colors = (
		keyword       => 4,
		comment       => 2,
		pod           => 2,
		string        => 9,
		plain         => 1,
	);

	return $colors{$css};
}

sub clear_style {
	my ( $styling_start_pos, $styling_end_pos ) = @_;
	
	my $doc    = Padre::Current->document;
	my $editor = $doc->editor;

	for my $i ( 0 .. 31 ) {
		$editor->StartStyling( $styling_start_pos, $i );
		$editor->SetStyling( $styling_end_pos - $styling_start_pos, 0 );
	}
}

sub get_range_at_pos {
	my ($pos, $matches) = @_;

	@$matches = grep { $_->{start} < $pos } @$matches;

	my $match = first { 
		   ( $_->{type} eq "pod" || $_->{type} eq "string" )
		&& ( ( $_->{start} + $_->{'length'} ) >= $pos )
	} @$matches;

	my $range;

	if ($match) {
		$range = $match->{range};
	}
	
	return \$range, $matches;

}

sub debug {
	#print @_;
}

sub db_match {
	#print @_;
}

sub db_pos {
	print @_;
}

1;

# Copyright 2009 Peter Shangov.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.




