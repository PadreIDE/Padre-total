package Padre::Wx::Popup;
use strict;
use warnings;

#use base 'Wx::ComboPopup';
#use base 'Wx::PopupTransientWindow';
#use base 'Wx::PopupWindow';
use base qw(Wx::PlPopupTransientWindow);

use Wx        qw(:everything);
use Wx::Event qw(:everything);

our $VERSION = '0.12';

sub on_paint {
    my( $self, $event ) = @_;
#    my $dc = Wx::PaintDC->new( $self );
#    $dc->SetBrush( Wx::Brush->new( Wx::Colour->new( 0, 192, 0 ), wxSOLID ) );
#    $dc->SetPen( Wx::Pen->new( Wx::Colour->new( 0, 0, 0 ), 1, wxSOLID ) );
#    $dc->DrawRectangle( 0, 0, $self->GetSize->x, $self->GetSize->y );

    
}
sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);
EVT_PAINT( $self, \&on_paint);

print "xxx $self\n";
#    my $panel =  Wx::Panel->new( $self, -1 );
#print "panel $panel\n";
    #$panel->SetBackgroundColour(Wx::wxWHITE);
#    $self->SetBackgroundColour(Wx::wxWHITE);
#print "aa\n";
#    my $dialog = Wx::Dialog->new( $self, -1, "", [-1, -1], [550, 200]);
#print "d $dialog\n";

#    my $st = Wx::StaticText->new($panel, -1, 
#           "abc adsda\n" .
#           "Some more\n" .
#           "and more\n"
#           , [10, 10], [-1, -1]);
#print "zz $st\n";
#    my $sz = $st->GetBestSize();
#    $self->SetSize( ($sz->GetWidth()+20, $sz->GetHeight()+20) );
    #$self->SetSize( $panel->GetSize());

    return $self;
}

sub ProcessLeftDown {
    my ($self, $event) = @_;
    print "Process Left $event\n";
    #$event->Skip;
    return 0;
}

sub OnDismiss {
    my ($self, $event) = @_;
    print "OnDismiss\n";
    #$event->Skip;
}

1;

