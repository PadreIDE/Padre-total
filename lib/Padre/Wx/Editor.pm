package Padre::Wx::Editor;

use 5.008;
use strict;
use warnings;

our $VERSION = '0.10';

use Wx::STC;
use base 'Wx::StyledTextCtrl';

use Wx   qw( wxTELETYPE wxNORMAL wxSTC_STYLE_DEFAULT wxSTC_H_TAG wxLayout_LeftToRight );
sub new {
	my( $class, $parent ) = @_;

	my $self = $class->SUPER::new( $parent );

	return $self;
}

# most of this should be read from some external files
# but for now we use this if statement
sub padre_setup {
	my ($self) = @_;

	$self->SetLexer( $self->{Padre}->lexer );
#	 $self->Colourise(0, $self->GetTextLength);

	my $mimetype = $self->{Padre}->mimetype;
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

	my $font = Wx::Font->new( 10, wxTELETYPE, wxNORMAL, wxNORMAL );

	$self->SetFont( $font );

	$self->StyleSetFont( wxSTC_STYLE_DEFAULT, $font );

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
	Wx->import(keys %colors);

	foreach my $k (keys %colors) {
		my @c = map {hex($_)} $colors{$k} =~ /(..)(..)(..)/;
		$self->StyleSetForeground( $k->(), Wx::Colour->new(@c));
	}

	# Set a style 12 bold
	$self->StyleSetBold(12,  1);

	# Apply tag style for selected lexer (blue)
	$self->StyleSetSpec( wxSTC_H_TAG, "fore:#0000ff" );

	if ( $self->can('SetLayoutDirection') ) {
		$self->SetLayoutDirection( wxLayout_LeftToRight );
	}

	return;
}


sub on_stc_update_ui {
	my ($self, $event) = @_;
	$self->update_status;
}

sub on_stc_style_needed {
	my ( $self, $event ) = @_;

	my $doc = Padre::Wx::MainWindow::_DOCUMENT() or return;
	if ($doc->can('colourise')) {
		$doc->colourise;
	}

}

sub on_stc_change {
	my ($self, $event) = @_;

	return if $self->{_in_setup_editor};
	my $config = Padre->ide->config;
	return if not $config->{editor_calltips};

	my $editor = $self->get_current_editor;

	my $pos    = $editor->GetCurrentPos;
	my $line   = $editor->LineFromPosition($pos);
	my $first  = $editor->PositionFromLine($line);
	my $prefix = $editor->GetTextRange($first, $pos); # line from beginning to current position
	   #$prefix =~ s{^.*?((\w+::)*\w+)$}{$1};
	if ($editor->CallTipActive) {
		$editor->CallTipCancel;
	}

    my $doc = Padre::Wx::MainWindow::_DOCUMENT() or return;
    my $keywords = $doc->keywords;

	my $regex = join '|', sort {length $a <=> length $b} keys %$keywords;

	my $tip;
	if ( $prefix =~ /($regex)[ (]?$/ ) {
		$tip = $keywords->{$1};
	}
	if ($tip) {
		$editor->CallTipShow($editor->CallTipPosAtStart() + 1, $tip);
	}

	return;
}

1;
