use strict;
use warnings;

use SDL;
use SDLx::App;
my $window = SDLx::App->new( 
    width => 640,
    height => 480, 
    depth => 16, 
    title => 'SDL Demo', ); 

my $rect = [0, 0, 10, 20]; 
my $blue = [ 0x00, 0x00, 0xff ]; 
$window->draw_rect($rect, $blue); 
$window->update($rect); 
sleep 2;
