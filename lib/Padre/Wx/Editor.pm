package Padre::Wx::Editor;

use 5.008;
use strict;
use warnings;

use Padre::Documents ();
use Wx::STC;
use Padre::Wx;

use base 'Wx::StyledTextCtrl';

our $VERSION = '0.13';

sub new {
	my( $class, $parent ) = @_;

	my $self = $class->SUPER::new( $parent );

	return $self;
}

# most of this should be read from some external files
# but for now we use this if statement
sub padre_setup {
	my ($self) = @_;

	$self->SetLexer( $self->{Document}->lexer );
#	 $self->Colourise(0, $self->GetTextLength);

	my $mimetype = $self->{Document}->mimetype;
    if ($mimetype eq 'text/perl') {
        $self->padre_setup_perl;
    } elsif ($mimetype) {
		# setup some default colouring
		# for the time being it is the same as for Perl
        $self->padre_setup_perl;
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

	$self->StyleSetForeground( 0,      Wx::Colour->new(0x00, 0x00, 0x7f));

	return;
}

sub padre_setup_perl {
	my ($self) = @_;

	$self->padre_setup_plain;

	no strict "refs";
	#my $str = "wxSTC_PL_DEFAULT";
	my %colors = (
		wxSTC_PL_DEFAULT       => '00007f',
		wxSTC_PL_ERROR         => 'ff0000',
		wxSTC_PL_COMMENTLINE   => '007f00', # line green
		wxSTC_PL_POD           => '7f7f7f',
		wxSTC_PL_NUMBER        => '007f7f',
		wxSTC_PL_WORD          => '00007f',
		wxSTC_PL_STRING        => 'ff7f00',  # orange
		wxSTC_PL_CHARACTER     => '7f007f',
		wxSTC_PL_PUNCTUATION   => '000000',
		wxSTC_PL_PREPROCESSOR  => '7f7f7f',
		wxSTC_PL_OPERATOR      => '00007f', # dark blue
		wxSTC_PL_IDENTIFIER    => '0000ff', # bright blue
		wxSTC_PL_SCALAR        => '7f007f', # purple
		wxSTC_PL_ARRAY         => '4080ff', # light blue
		wxSTC_PL_HASH          => '0080ff',
		wxSTC_PL_SYMBOLTABLE   => '000000',
		# missing SCE_PL_VARIABLE_INDEXER (16)  
		wxSTC_PL_REGEX         => 'ff007f', # red
		wxSTC_PL_REGSUBST      => '7f7f00', # light olive
		# wxSTC_PL_LONGQUOTE (19)
		# wxSTC_PL_BACKTICKS (20)
		# wxSTC_PL_DATASECTION (21)
		# wxSTC_PL_HERE_DELIM (22)
		wxSTC_PL_HERE_Q        => '7f007f',
		# wxSTC_PL_HERE_QQ (24)
		# wxSTC_PL_HERE_QX (25)
		wxSTC_PL_STRING_Q      => '7f007f',
		wxSTC_PL_STRING_QQ     => 'ff7f00', # orange
		# wxSTC_PL_STRING_QX  (28)
		wxSTC_PL_STRING_QR     => 'ff007f', # red
		wxSTC_PL_STRING_QW     => '7f007f',

		# missing:
		#define SCE_PL_POD_VERB 31
		#define SCE_PL_SUB_PROTOTYPE 40
		#define SCE_PL_FORMAT_IDENT 41
		#define SCE_PL_FORMAT 42
	);

	foreach my $k (keys %colors) {
		my @c = map {hex($_)} $colors{$k} =~ /(..)(..)(..)/;
		my $f = 'Wx::' . $k;
		$self->StyleSetForeground( $f->(), Wx::Colour->new(@c));
	}

	# Set a style 12 bold
	$self->StyleSetBold(12,  1);

	# Apply tag style for selected lexer (blue)
	$self->StyleSetSpec( Wx::wxSTC_H_TAG, "fore:#0000ff" );

	if ( $self->can('SetLayoutDirection') ) {
		$self->SetLayoutDirection( Wx::wxLayout_LeftToRight );
	}

	return;
}


sub check_for_brace {
	my ($self) = @_;

	my $pos1  = $self->GetCurrentPos;
	#print "$pos1\n";
	return;
	my $pos2  = $self->BraceMatch($pos1);
	if ($pos2 == -1 ) {   #Wx::wxSTC_INVALID_POSITION
		if ($pos1 > 0) {
			$pos1--;
			$pos2 = $self->BraceMatch($pos1);
		}
	}

	if ($pos2 != -1 ) {   #Wx::wxSTC_INVALID_POSITION
		#print "$pos1 $pos2\n";
		#$page->BraceHighlight($pos1, $pos2);
		#$page->SetCurrentPos($pos2);
		$self->GotoPos($pos2);
		#$page->MoveCaretInsideView;
	}
}
sub highlight_brace {
	my ($self) = @_;

	$self->IndicatorSetStyle(1, 6);
	$self->IndicatorSetForeground(1, Wx::Colour->new(0x00, 0xFF, 0x00));
	#$self->StartStyling($m->[0],         Wx::wxSTC_INDIC1_MASK);
	#$self->SetStyling(  $m->[1]-$m->[0], Wx::wxSTC_INDIC1_MASK);
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

	$self->SetTabWidth( $config->{editor_tabwidth} );
	$self->SetUseTabs(  $config->{editor_use_tabs} );

	return;
}


1;
