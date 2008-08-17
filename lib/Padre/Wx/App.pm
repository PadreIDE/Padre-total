package Padre::Wx::App;

use strict;
use warnings;

our $VERSION = '0.01';

use base 'Wx::App';
use Padre::Frame;

our $frame;
sub OnInit {
    $frame = Padre::Frame->new;
    $frame->Show( 1 );
}

1;
