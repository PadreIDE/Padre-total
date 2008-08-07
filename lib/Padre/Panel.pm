package Padre::Panel;
use strict;
use warnings;

our $VERSION = '0.01';
use Wx::STC;
use base 'Wx::StyledTextCtrl';

use Wx;
use Wx qw(:stc :textctrl :font wxDefaultPosition wxDefaultSize :id
          wxNO_FULL_REPAINT_ON_RESIZE wxLayout_LeftToRight);
use Wx qw(wxDefaultPosition wxDefaultSize wxTheClipboard 
          wxDEFAULT_FRAME_STYLE wxNO_FULL_REPAINT_ON_RESIZE wxCLIP_CHILDREN);
use Wx::Event qw(EVT_TREE_SEL_CHANGED EVT_MENU EVT_CLOSE EVT_STC_CHANGE);

sub new {
    my( $class, $parent, $lexer ) = @_;
    my $self = $class->SUPER::new( $parent, -1, [-1, -1], [750, 700]); # TODO get the numbers from the frame?

    my $font = Wx::Font->new( 10, wxTELETYPE, wxNORMAL, wxNORMAL );

    $self->SetFont( $font );

    $self->StyleSetFont( wxSTC_STYLE_DEFAULT, $font );
    $self->StyleClearAll();

    $self->StyleSetForeground(0, Wx::Colour->new(0x00, 0x00, 0x7f));
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

    #Set a style 12 bold
    $self->StyleSetBold(12,  1);

    # Apply tag style for selected lexer (blue)
    $self->StyleSetSpec( wxSTC_H_TAG, "fore:#0000ff" );

    $self->SetLexer( $lexer );

    $self->SetLayoutDirection( wxLayout_LeftToRight )
      if $self->can( 'SetLayoutDirection' );

    ##print $self->GetModEventMask() & wxSTC_MOD_INSERTTEXT;
    ##print "\n";
    #$self->SetModEventMask( wxSTC_MOD_INSERTTEXT  | wxSTC_PERFORMED_USER );
    #EVT_STC_CHANGE($self, -1, \&on_change );
    return $self;
}

sub on_change {
    #print "@_\n";
    my $nb = $Padre::Frame::nb;
    #print $nb->GetCurrentPage, "\n";
    print $nb->GetSelection, "\n";
    return;
}


1;

