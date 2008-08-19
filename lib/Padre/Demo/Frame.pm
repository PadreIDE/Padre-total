package Padre::Demo::Frame;

use 5.008;
use strict;
use warnings;
use File::Spec         ();
use Wx                 qw(:everything);
use Wx::STC            ();
use Wx::Event          qw(:everything);
use Padre::Demo::App   ();
use Padre::Demo::Frame ();
use base 'Wx::Frame';

my $output;

sub print_out {
    my ($self, $text) = @_;
    $output->AddText($text);
    return;
}


sub new {
    my ($class) = @_;

    my $self = $class->SUPER::new(
        undef,
        -1,
        'Padre::Demo::App',
        wxDefaultPosition,
        wxDefaultSize,
    );

    $output = Wx::StyledTextCtrl->new($self, -1, [-1, -1], [750, 700]);
    $output->SetMarginWidth(1, 0);

    EVT_ACTIVATE($self, \&on_activate);

    Wx::Event::EVT_CLOSE( $self,  sub {
         my ( $self, $event ) = @_;
         $event->Skip;
    } );

    return $self;
}

sub on_activate {
   my ($frame, $event) = @_;

   $frame->EVT_ACTIVATE(sub {});
   #$Padre::Demo::app->Yield;
   return $Padre::Demo::main->($frame);
}

1;
