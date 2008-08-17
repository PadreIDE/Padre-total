package Padre::Wx::Text;

use strict;
use warnings;

our $VERSION = '0.01';

use Wx::STC;
use base 'Wx::StyledTextCtrl';

use Wx        qw(:everything);
use Wx::Event qw(:everything);

sub new {
    my( $class, $parent, $lexer ) = @_;

    # TODO get the numbers from the frame?
    my $self = $class->SUPER::new( $parent, -1, [ -1, -1 ], [ 750, 700 ] );

    my $font = Wx::Font->new( 10, wxTELETYPE, wxNORMAL, wxNORMAL );

    $self->SetFont( $font );

    $self->StyleSetFont( wxSTC_STYLE_DEFAULT, $font );
    $self->StyleClearAll();

    $self->StyleSetForeground(0,  Wx::Colour->new(0x00, 0x00, 0x7f));
    $self->StyleSetForeground(1,  Wx::Colour->new(0xff, 0x00, 0x00));

    # 2 Comment line green
    $self->StyleSetForeground(2,  Wx::Colour->new(0x00, 0x7f, 0x00));
    $self->StyleSetForeground(3,  Wx::Colour->new(0x7f, 0x7f, 0x7f));

    # 4 numbers
    $self->StyleSetForeground(4,  Wx::Colour->new(0x00, 0x7f, 0x7f));
    $self->StyleSetForeground(5,  Wx::Colour->new(0x00, 0x00, 0x7f));

    # 6 string orange
    $self->StyleSetForeground(6,  Wx::Colour->new(0xff, 0x7f, 0x00));

    $self->StyleSetForeground(7,  Wx::Colour->new(0x7f, 0x00, 0x7f));

    $self->StyleSetForeground(8,  Wx::Colour->new(0x00, 0x00, 0x00));

    $self->StyleSetForeground(9,  Wx::Colour->new(0x7f, 0x7f, 0x7f));

    # 10 operators dark blue
    $self->StyleSetForeground(10, Wx::Colour->new(0x00, 0x00, 0x7f));

    # 11 identifiers bright blue
    $self->StyleSetForeground(11, Wx::Colour->new(0x00, 0x00, 0xff));

    # 12 scalars purple
    $self->StyleSetForeground(12, Wx::Colour->new(0x7f, 0x00, 0x7f));

    # 13 array light blue
    $self->StyleSetForeground(13, Wx::Colour->new(0x40, 0x80, 0xff));

    # 17 matching regex red
    $self->StyleSetForeground(17, Wx::Colour->new(0xff, 0x00, 0x7f));

    # 18 substitution regex light olive
    $self->StyleSetForeground(18, Wx::Colour->new(0x7f, 0x7f, 0x00));

    # Set a style 12 bold
    $self->StyleSetBold(12,  1);

    # Apply tag style for selected lexer (blue)
    $self->StyleSetSpec( wxSTC_H_TAG, "fore:#0000ff" );

    $self->SetLexer( $lexer );

    if ( $self->can('SetLayoutDirection') ) {
        $self->SetLayoutDirection( wxLayout_LeftToRight );
    }

    return $self;
}

1;
