use strict;
use warnings;

use SDL::App;

# this script will draw a line

my $width = 640;
my $height = 480;

my $window = SDL::App->new(
	-width => $width,
	-height => $height,
	-depth => 16,
	-title => 'SDL Demo',
);

my $x = 0;
my $y = 0;
my $dir = 'right';

my $rect = SDL::Rect->new( -height => 2, -width => 2);
my $bg_color = SDL::Color->new(
	-r => 0x00,
	-g => 0x00,
        -b => 0x00,
        );
my $rect_color = SDL::Color->new(
	-r => 0x00,
	-g => 0x00,
        -b => 0xff,
        );

my $bg = SDL::Rect->new(
	-width  => $width,
	-height => $height,
);



# clear background
$window->fill( $bg, $bg_color );


# draw a line
for (1..100) {
	$rect->x( $_ );
	$rect->y( $_ );
	
	$window->fill( $rect, $rect_color );
	$window->update( $bg );
}

sleep 2;

