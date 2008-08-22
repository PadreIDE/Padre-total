package Padre::Demo::App;

use 5.008;
use strict;
use warnings;
use base 'Wx::App';

use Padre::Demo::Frame;

our $frame;
our $output;

sub OnInit {
    $frame = Padre::Demo::Frame->new;
    $output = Padre::Demo::open_frame();
    $frame->Show( 1 );
    return 1;
}

1;
