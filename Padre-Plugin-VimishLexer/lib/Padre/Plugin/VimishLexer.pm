package Padre::Plugin::VimishLexer;
use strict;
use warnings;
use 5.008;

our $VERSION = '0.01';

use Padre::Wx ();
use Padre::Current;
use Regexp::Assemble;
use IO::Scalar;
use List::Util qw(first);
use Data::Dumper qw(Dumper);

use base 'Padre::Plugin';

=head1 NAME

Padre::Plugin::VimishLexer - Using the Vimish syntax highlighter

=head1 SYNOPSIS

This plugin provides an interface to the L<Syntax::Highligh::Engine::Kate>
which implements syntax highlighting rules taken from the Kate editor.

Currently the plugin only implements Perl 5 and PHP highlighting.

Once this plug-in is installed the user can switch the highlilghting of all 
Perl 5 or PHP files to use this highlighter via the Preferences menu
of L<Padre>.


=head1 LIMITATION

This is a first attempt to integrate this synatx highlighter with Padre
and thus many things don't work well. Especially due to speed issues currently
even if you set the highlighting to use the Kate plugin Padre will do so
only for small files. The hard-coded limit is in the 
L<Padre::Document::Perl> class (which probably is a bug in itself) which
probably means it will only limit Perl files and not PHP files.

There are several ways to improve the situation e.g.

Highlight in the background

Only highlight the currently visible text

Only highlight a few lines around the the last changed character.

Each one has its own advantage and disadvantage. More research is needed.

=head1 COPYRIGHT

Copyright 2009 Gabor Szabo. L<http://szabgab.com/>

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl 5 itself.

=cut

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

# TODO shall we create a module for each mime-type and register it as a highlighter
# or is our dispatching ok?
# Shall we create a module called Pudre::Plugin::Kate::Colorize that will do the dispatching ?
# now this is the mapping to the Kate highlighter engine
my %d = (
	'application/x-perl' => 'Perl',
);

my @keywords = qw( 
	if elsif else unless while for foreach do continue until defined undef
	and or not bless ref my local our sub package use shift
);

#my $re = Regexp::Assemble->new;
#my @prepared_kewords = map { "^" . $_ . "\b"} @keywords;
#$re->add(@prepared_kewords);
@keywords = map { $_ . '\b'} @keywords;
my $re = "^(" . join("|", @keywords, ) . ")";

my @define = (
	{ type => 'range',    name => 'pod',     start => qr(^=[a-z]), end => qr(=cut\b), start_first => 1, end_first => 1},
	{ type => 'range',    name => 'string',  start => qr(^"), end => qr(") },
	{ type => 'range',    name => 'string',  start => qr(^'), end => qr(') },
	{ type => 'match',    name => 'comment', pattern => qr(^#.*$) },
	{ type => 'literal',  name => 'keyword', pattern => $re },
);


my @matches;

my $current_range;
my $current_position;
my $line_start;
my $c = 1;

sub parse_doc {
	my $text_to_parse = shift;
	my $initial_offset = shift;
	my $doc = IO::Scalar->new(\$text_to_parse);
	$current_position = $initial_offset;

	while ( defined( my $line = $doc->getline ) ) {
		my $last;
		if ($doc->eof) {
			$last = 1;
		}
		$line_start = 1;
		my $pos = $doc->tell;
		$pos += $initial_offset;
		debug( "LINE " . Padre::Current->document->editor->LineFromPosition($pos) . " ===>\n" );
		parse_line($line, $last);
		debug( "$current_position - $pos - $initial_offset; line: $line\n" );
		if ($current_position < $pos) {
			$current_position = $pos;
		};
		debug( "New position: $pos\n" );
	}

	if ($current_range) {
		add_match(0, $current_range->{name}, "", $current_range->{start_pos});
		debug( "### RANGE AUTO END ###\n" );
	}
}

sub parse_line {
	my $line = shift;
	my $last = shift;

	# there are no more interesting sybols in the line
	if ( $line !~ /\S+/ ) {
		return;
	}

	my $copy_line = $line;
	chomp $copy_line;
	debug( $c++ . " ($current_position): " . $copy_line . "\n" );

	# are we inside a range?
	if ($current_range) {
		return if $current_range->{end_first} and !$line_start;
		
		# do we have a range end?
		if ( $line =~ $current_range->{end} ) 
		{
			add_match($+[0], $current_range->{name}, $line, $current_range->{start_pos});

			# clear the current range variable
			undef $current_range;
					
			debug( "### RANGE END ###\n" );
			return;
		} 
		# nothing interesting to do
		else
		{
			$current_position += length($line);
			return;
		}
	}
	# search for interesting patterns
	else
	{
		foreach my $rule (@define) {
			next if $rule->{start_first} and !$line_start;

			if ( $rule->{type} eq 'range' ) {
				if ( $line =~ $rule->{start} ) {
					my $offset = $+[0];
					
					debug( "### RANGE START ###\n" );

					$current_range = $rule;
					$current_range->{start_pos} = $current_position;

					my $remaining = substr($line, $offset);
					$current_position += $offset;

					undef $line_start;
					parse_line($remaining) if $remaining;

					return;
				}
				debug( "no range " . $rule->{name} . "!\n" );
			} elsif ( $rule->{type} eq 'match' ) {
				if ( $line =~ $rule->{pattern} ) {
					add_match($+[0], $rule->{name}, $line);
					return;
				}
				debug( "no match " . $rule->{name} . "!\n" );
			} elsif ( $rule->{type} eq 'literal' ) {
				if ( $line =~ $rule->{pattern} ) {
					my $end_pos = $+[0];
					add_match($+[0], "keyword", $line);	
					return;
				}
				debug( "no keyword!\n" );
			}
		}
		
		# if a some keyword has started and has not matched, delete till the end of it;
		# don't do substr if we have already deleted stuff
		my $modified_chars = 0;
		$modified_chars += length $1 if $line =~ s/^(((::)*\w+)+)//;
		$modified_chars += length $1 if $line =~ s/^(\s+)//;

		if ($line) {
			my $remaining;
			
			if ($modified_chars) {
				$remaining = $line;
				$current_position += $modified_chars;
				debug( "Modified chars: $modified_chars\n" );
			} else { 
				$current_position++;
				$remaining = substr($line, 1); 
			}
			
			undef $line_start;
			parse_line($remaining);
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

sub colorize {
	db("COLORIZE\n");
	my $class = shift;

	my $doc    = Padre::Current->document;
	my $editor = $doc->editor;

	# 1. get start and end position from Wx::STC
	my ( $start_pos, $end_pos ) = @_;
	$start_pos ||= 0;
	#$end_pos   ||= $editor->GetLength;

	my $saved_end_pos = $end_pos;

	# 2. move start position to begginning of line
	my $start_pos_line = $editor->LineFromPosition($start_pos);
	$start_pos = $editor->PositionFromLine($start_pos_line) if $start_pos;
	
	my $initial_offset = 0;
	$initial_offset = $start_pos - 1 if $start_pos > 0;

	# 3. move end position to end of visible area, and then some
	my $last_visible_line = $editor->GetFirstVisibleLine + $editor->LinesOnScreen;
	my $last_visible_line_plus_50 = $last_visible_line + 50;
	my $total_line_count = $editor->GetLineCount;
	
	$last_visible_line_plus_50 > $total_line_count 
		? $end_pos = $editor->GetLineEndPosition( $total_line_count - 1 )
		: $end_pos = $editor->GetLineEndPosition( $last_visible_line_plus_50 - 1 );

	# 4. parse the segment
	
	my $full_text = $doc->text_get;
	my $text_to_parse = $editor->GetTextRange( $start_pos, $end_pos );
	return unless $text_to_parse;
	
	# prepare
	$current_position = 0;
	undef $current_range;
	undef $line_start;
	$c = 1;

	# check if start position is within a range
	(my $start_range, @matches) = get_range_at_pos($start_pos);
	$current_range = $start_range if $start_range;

	print( "COLORIZE FROM $start_pos =============>\n" );
	print "CURRENT RANGE: ";
	if ( defined $current_range ) {
		print $current_range->{name};
	} else {
		print "NONE";
	}
	print " =============>\n";

	#parse_doc($text_to_parse, $initial_offset);
	parse_doc($text_to_parse, $start_pos);

	# 6. clear the color from the start of the segment on
	clear_style($start_pos, $editor->GetLength);
	# $doc->remove_color;
	
	# 7. colorize the segment
	foreach my $m (@matches) {
		$editor->StartStyling( $m->{start}, $m->{color} );
		$editor->SetStyling( $m->{length}, $m->{color} );	

		debug( $m->{type} . ":"  . $m->{start} . ":" . $m->{length} 
		      . ":" . substr($full_text, $m->{start}, $m->{length}) . "\n" );
	}

	my $last_match = $matches[-1];
	if ($last_match) {
		my $last_match_start = $last_match->{start} + $last_match->{length};
		if ($last_match_start >= $editor->GetEndStyled && $saved_end_pos == $editor->GetLength) {
			$editor->StartStyling( $last_match_start, 1 );
			$editor->SetStyling( 1, 1 );
			debug( "end" . ":"  . $last_match_start . ":" . 1 
		    	  . ":" . substr($full_text, $last_match_start, 1) . "\n" );
			debug("GetEndStyled: " . $editor->GetEndStyled . "\n");
		}
	}
	# debug("End position passed by Scintilla: $saved_end_pos\n" );
	# debug("\$last_match_start: $last_match_start\n" );
	# debug("GetLength: " . $editor->GetLength . "\n" );
	# debug("GetEndStyled: " . $editor->GetEndStyled . "\n" );
}

sub class_to_color {
	my $css  = shift;
	my %colors = (
		keyword       => 4,
		comment       => 2,
		pod           => 2,
		string        => 9,
		end           => 1,
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

sub about {
	my ($main) = @_;

	my $about = Wx::AboutDialogInfo->new;
	$about->SetName(__PACKAGE__);
	$about->SetDescription("Trying to use the Vimish lexer for syntax highlighting\n" );
	$about->SetVersion($VERSION);
	Wx::AboutBox($about);
	return;
}

sub debug {
	print @_;
}

sub db {
	#print @_;
}

1;

# Copyright 2008-2009 Gabor Szabo.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.




