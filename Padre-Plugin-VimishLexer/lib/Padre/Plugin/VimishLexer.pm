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
use Perl6::Caller;

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

	# Padre may sometimes call colorize() without arguments when it needs
	# the whole document styled
	$start_pos = 0 unless defined $start_pos;

	debug("\n=== COLORIZE($start_pos, $end_pos) CALLED! ===\n");

	# both $start_pos and $end_pos may be modified, but we will
	# need a copy of the original $end_pos below
	my $original_stc_end_pos = $end_pos;

	my $doc    = Padre::Current->document;
	my $editor = $doc->editor;
	my $matches = $doc->{__VimishLexer}{matches};

	### DETERMINE THE $start_pos THAT WE WILL PASS TO parse_code() ###
	
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

	
	
	### PARSE ###
	parse_code($doc->text_get, $start_pos, $end_pos, $matches);

	### APPLY THE COLORS ###

	# clear the color from the start of the segment on
	clear_style($start_pos, $editor->GetLength);
	# $doc->remove_color;
	
	# colorize the segment
	foreach my $m ($@matches) {
		$editor->StartStyling( $m->{start}, $m->{color} );
		$editor->SetStyling( $m->{length}, $m->{color} );	

		debug( $m->{type} . ":"  . $m->{start} . ":" . $m->{length} 
		      . ":" . substr($full_text, $m->{start}, $m->{length}) . "\n" );
	}

	$doc->{__VimishLexer}{matches} = $matches)
	

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
	my ($current_range, $matches) = get_range_at_pos($start_pos, $matches);

	my $text_to_parse = substr($text, $start_pos, $end_pos - $start_pos);
	my $code = IO::Scalar->new(\$text_to_parse);

	# $line_start - true if we are at the start of a line, false otherwise
	my $line_start;

	while ( defined( my $line = $code->getline ) ) {
		# make sure the parser knows that we are starting to parse a new line
		$line_start = 1;

		### DEBUG ###
		debug( "LINE " . Padre::Current->document->editor->LineFromPosition($start_pos) . " ===>\n" );
		
		parse_line($line, $current_position, $current_range, $matches);

		# update the current position to the end of the line we just parsed 
		# requied because of space and newline characters at the end of the lines
		$current_position = $code->tell + $start_pos;
	}
	
	# if after we finished parsing $current_range is defined,
	# automatically close the range
	if ($current_range) {
		add_match(0, $current_range->{name}, "", $current_range->{start_pos});
		debug( "range auto end!\n" );
	}

	# make sure that if we are the end of the file the last character is colorized,
	# otherwise Scintilla will keep firing an ON_STYLENEEDED event every time the
	# last line is visible
	my $last_match = $matches[-1];
	if ($last_match) {
		my $last_match_start = $last_match->{start} + $last_match->{length};
		if ($last_match_start >= $editor->GetEndStyled && $original_stc_end_pos == $editor->GetLength) {
			$editor->StartStyling( $last_match_start, 1 );
			$editor->SetStyling( 1, 1 );
			debug( "end" . ":"  . $last_match_start . ":" . 1 
		    	  . ":" . substr($full_text, $last_match_start, 1) . "\n" );
			debug("GetEndStyled: " . $editor->GetEndStyled . "\n");
		}
	}
}

###########################
### PARSE A SINGLE LINE ###
###########################

# Returns nothing, it just updates @matches
# Called by: parse_code()

sub parse_line {
	my ($line, $current_position, $current_range, $matches) = @_;
	
	# if parse_line() has recursively called itself, then we
	# are not at the start of a line
	my $line_start = 1 unless caller->subroutine eq "parse_line";

	# there are no interesting sybols in the line
	# don't bother updating $current_position, parse_code()
	# takes care of that
	if ( $line !~ /\S+/ ) {
		return;
	}

	### DEBUG ###
	debug( "POS: $current_position, LINE: $line" );

	# the bulk of the parsing takes place here
	if (!$current_range) {
		foreach my $rule (@define) {
			next if $rule->{start_first} and !$line_start;

			if ( $rule->{type} eq 'range' ) {
				if ( $line =~ $rule->{start} ) {
					# $offset contains the number of characters matched 
					# by the $rule->{start} regex
					my $offset = $+[0];
					
					# set $current_range
					$current_range = $rule;
					$current_range->{start_pos} = $current_position;
					
					# continue parsing
					debug( "range start found!\n" );
					$current_position += $offset;
					undef $line_start;
					my $remaining = substr($line, $offset);
					parse_line($remaining) if $remaining;
					
					return;
				}
			} elsif ( $rule->{type} eq 'match' ) {
				if ( $line =~ $rule->{pattern} ) {
					add_match($+[0], $rule->{name}, $line);
					debug( "match found!\n" );
					return;
				}
			} elsif ( $rule->{type} eq 'literal' ) {
				if ( $line =~ $rule->{pattern} ) {
					add_match($+[0], "keyword", $line);	
					debug( "keyword found!\n" );
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
			parse_line($remaining);
		}
	}
	# if we are inside a range, try to find its end
	else
	{
		# $current_position is updated by parse_code()
		return if $current_range->{end_first} and !$line_start;
		
		# do we have a range end?
		if ( $line =~ $current_range->{end} ) 
		{
			add_match($+[0], $current_range->{name}, $line, $current_range->{start_pos});

			# clear the current range variable
			undef $current_range;
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
	my ($length, $type, $line, $start_pos) = @_;
	my $offset = 0;
	
	if ($start_pos) {
		debug( "Length: $length, Line: $line, Start: $start_pos, Current: $current_position\n" );
		$offset = $current_position - $start_pos;
		#$length += $offset;
	} else {
		 $start_pos = $current_position;
	}

	my $remaining = substr($line, $length) if $line;

	# update the global current position
	$current_position += $length unless $type eq "range";

	push @matches, { 
		start  => $start_pos,
		length => $length + $offset,
		color  => class_to_color($type),
		type   => $type,
		range  => $current_range,
	};

	# parse the remainder of the line
	undef $line_start;
	parse_line($remaining) if $remaining;
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
	my $pos = shift;
	my $range;

	my @matches_up_to_pos = grep { $_->{start} <= $pos } @matches;

	my $match = first { 
		   ( $_->{type} eq "pod" || $_->{type} eq "string" )
		&& ( ( $_->{start} + $_->{'length'} ) >= $pos )
	} @matches_up_to_pos;

	#debug("GET_RANGE_AT_POS\n");
	#debug($match . "\n");
	debug( Dumper(\@matches_up_to_pos) );

	$match ? return $match->{range}, @matches_up_to_pos 
	       : return undef, @matches_up_to_pos ;
}

sub debug {
	print @_;
}

1;

# Copyright 2008-2009 Gabor Szabo.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.



