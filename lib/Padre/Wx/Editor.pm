package Padre::Wx::Editor;

use 5.008;
use strict;
use warnings;

use YAML::Tiny      ();

use Padre::Documents ();
use Wx::STC;
use Padre::Wx;

use base 'Wx::StyledTextCtrl';

our $VERSION = '0.15';

my $data;

sub new {
	my( $class, $parent ) = @_;

	my $self = $class->SUPER::new( $parent );
	$data = data();

	return $self;
}

sub data {
	unless ( defined $data ) {
		$data = YAML::Tiny::LoadFile(
			Padre::Wx::sharefile( 'styles', 'default.yml' )
		);
	}
	return $data;
}


# most of this should be read from some external files
# but for now we use this if statement
sub padre_setup {
	my ($self) = @_;

	$self->SetLexer( $self->{Document}->lexer );
#	 $self->Colourise(0, $self->GetTextLength);

	# the next line will change the ESC key to cut the current selection
	# See: http://www.yellowbrain.com/stc/keymap.html
	#$self->CmdKeyAssign(Wx::wxSTC_KEY_ESCAPE, 0, Wx::wxSTC_CMD_CUT);

	$self->SetCodePage(65001); # which is supposed to be wxSTC_CP_UTF8
	# and Wx::wxUNICODE() or wxUSE_UNICODE should be on

	my $mimetype = $self->{Document}->mimetype;
    if ($mimetype eq 'text/perl') {
        $self->padre_setup_style('perl');
    } elsif ($mimetype eq 'text/pasm') {
        $self->padre_setup_style('pasm');
    } elsif ($mimetype) {
		# setup some default colouring
		# for the time being it is the same as for Perl
        $self->padre_setup_style('perl');
	} else {
		# if mimetype is not known, then no colouring for now
		# but mimimal conifuration should apply here too
        $self->padre_setup_plain;
	}

    return;
}

sub padre_setup_plain {
	my $self = shift;

	my $font = Wx::Font->new( 10, Wx::wxTELETYPE, Wx::wxNORMAL, Wx::wxNORMAL );

	$self->SetFont( $font );

	$self->StyleSetFont( Wx::wxSTC_STYLE_DEFAULT, $font );

	$self->StyleClearAll();

	foreach my $k (keys %{ $data->{plain}{forgrounds} }) {
		$self->StyleSetForeground( $k, _colour( $data->{plain}{foregrounds}{$k} ) );
	}
	
	#$self->StyleSetBold(12,  1);

	# Apply tag style for selected lexer (blue)
	$self->StyleSetSpec( Wx::wxSTC_H_TAG, "fore:#0000ff" );

	if ( $self->can('SetLayoutDirection') ) {
		$self->SetLayoutDirection( Wx::wxLayout_LeftToRight );
	}

	return;
}

sub padre_setup_style {
	my ($self, $name) = @_;

	$self->padre_setup_plain;

	no strict "refs";
	foreach my $k ( keys %{ $data->{$name}{colors} }) {
		my $f = 'Wx::' . $k;
		my $v = eval {$f->()};
		if ($@) {
			$f = 'Px::' . $k;
			$v = eval {$f->()};
			if ($@) {
				warn "invalid key '$k'\n";
				next;
			}
		}

		$self->StyleSetForeground( $f->(), _colour($data->{$name}{colors}{$k}) );
	}

	$self->StyleSetBackground(34, _colour($data->{$name}{brace_highlight}));

	return;
}

sub _colour {
	my $rgb = shift;
	my @c = map {hex($_)} $rgb =~ /(..)(..)(..)/;
	return Wx::Colour->new(@c)
}

sub highlight_braces {
	my ($self) = @_;

	$self->BraceHighlight(-1, -1); # Wx::wxSTC_INVALID_POSITION
	my $pos1  = $self->GetCurrentPos;
	my $chr = chr($self->GetCharAt($pos1));

	my @braces = ( '{', '}', '(', ')', '[', ']');
	if (not grep {$chr eq $_} @braces) {
		if ($pos1 > 0) {
			$pos1--;
			$chr = chr($self->GetCharAt($pos1));
			return unless grep {$chr eq $_} @braces;
		}
	}
	
	my $pos2  = $self->BraceMatch($pos1);
	return if abs($pos1-$pos2) < 2;

	return if $pos2 == -1;   #Wx::wxSTC_INVALID_POSITION  #????
	
	$self->BraceHighlight($pos1, $pos2);

	return;
}


# currently if there are 9 lines we set the margin to 1 width and then
# if another line is added it is not seen well.
# actually I added some improvement allowing a 50% growth in the file
# and requireing a min of 2 width
sub show_line_numbers {
	my ($self, $on) = @_;

	$self->SetMarginWidth(1, 0);
	$self->SetMarginWidth(2, 0);
	if ($on) {
		my $n = 1 + List::Util::max (2, length ($self->GetLineCount * 2));
		my $width = $n * $self->TextWidth(Wx::wxSTC_STYLE_LINENUMBER, "9"); # width of a single character
		$self->SetMarginWidth(0, $width);
		$self->SetMarginType(0, Wx::wxSTC_MARGIN_NUMBER);
	} else {
		$self->SetMarginWidth(0, 0);
		$self->SetMarginType(0, Wx::wxSTC_MARGIN_NUMBER);
	}

	return;
}

sub set_preferences {
	my ($self) = @_;

	my $config = Padre->ide->config;

	$self->show_line_numbers(    $config->{editor_linenumbers}       );
	$self->SetIndentationGuides( $config->{editor_indentationguides} );
	$self->SetViewEOL(           $config->{editor_eol}               );

	$self->SetTabWidth( $config->{editor_tabwidth} );
	$self->SetUseTabs(  $config->{editor_use_tabs} );

	return;
}

sub show_calltip {
	my ($self) = @_;

	my $config = Padre->ide->config;
	return if not $config->{editor_calltips};


	my $pos    = $self->GetCurrentPos;
	my $line   = $self->LineFromPosition($pos);
	my $first  = $self->PositionFromLine($line);
	my $prefix = $self->GetTextRange($first, $pos); # line from beginning to current position
	   #$prefix =~ s{^.*?((\w+::)*\w+)$}{$1};
	if ($self->CallTipActive) {
		$self->CallTipCancel;
	}

    my $doc = Padre::Documents->current or return;
    my $keywords = $doc->keywords;

	my $regex = join '|', sort {length $a <=> length $b} keys %$keywords;

	my $tip;
	if ( $prefix =~ /($regex)[ (]?$/ ) {
		my $z = $keywords->{$1};
		return if not $z or not ref($z) or ref($z) ne 'HASH';
		$tip = "$z->{cmd}\n$z->{exp}";
	}
	if ($tip) {
		$self->CallTipShow($self->CallTipPosAtStart() + 1, $tip);
	}
	return;
}

# 1) get the white spaces of the previous line and add them here as well
# TODO: 2) after a brace indent one level more than previous line
sub autoindent {
	my ($self) = @_;

	my $pos       = $self->GetCurrentPos;
	my $prev_line = $self->LineFromPosition($pos) -1;
	return if $prev_line < 0;

	my $start     = $self->PositionFromLine($prev_line);
	my $end       = $self->GetLineEndPosition($prev_line);
	#my $length    = $self->LineLength($prev_line);
	my $content   = $self->GetTextRange($start, $end);
	#print "'$content'\n";
	if ($content =~ /^(\s+)/) {
		my $indent = $1;
		$self->InsertText($pos, $indent);
		$self->GotoPos($pos + length($indent));
	}

	return;
}

1;

# Copyright 2008 Gabor Szabo.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.
