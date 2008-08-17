package Padre::Demo::App;

use 5.008;
use strict;
use warnings;
use base 'Wx::App';

our $frame;

sub OnInit {
    $frame = Padre::Demo::Frame->new;
    $frame->Show( 1 );
}

1;
