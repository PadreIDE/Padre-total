use strict;
use warnings;

use SDL;
use SDL::App;
use SDL::Color;
use SDL::Rect;

# moving a blue rectangle through a window

# based on SDL::Tutorial::Animation

my $width = 640;
my $height = 480;

my $window = SDL::App->new(
	-width => $width,
	-height => $height,
	-depth => 16,
	-title => 'SDL Demo',
);

my $rect = SDL::Rect->new( -height => 10, -width => 20);
my $bg_color = SDL::Color->new(
	-r => 0x00,
	-g => 0x00,
        -b => 0x00,
        );
my $color = SDL::Color->new(
	-r => 0x00,
	-g => 0x00,
        -b => 0xff,
        );

my $bg = SDL::Rect->new(
	-width  => $width,
	-height => $height,
);

sub draw_frame {
	my ($app, %args) = @_;
	$app->fill( $args{ bg }, $args{ bg_color } );
	$app->fill( $args{rect}, $args{rect_color} );
	$app->update( $args{bg} );
}

for my $x (0 .. 640) {
	$rect->x( $x );
	draw_frame( $window,
		bg         => $bg,   
		bg_color   => $bg_color,
		rect       => $rect, 
		rect_color => $color,
	);
}
        

