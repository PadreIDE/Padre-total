use strict;
use warnings;

use SDL;
use SDL::App;
use SDL::Color;
use SDL::Rect;


my $box_width  = 16;
my $box_height = 16;
my $n_width    = 20;
my $n_height   = 10;

my $width  = $box_width * $n_width;
my $height = $box_height * $n_height;

my $window = SDL::App->new(
	-width => $width,
	-height => $height,
	-depth => 16,
	-title => 'SDL Map',
);
my $bg_color = SDL::Color->new(
	-r => 0x00,
	-g => 0x00,
	-b => 0x00,
);
my $bg = SDL::Rect->new(
	-width  => $width,
	-height => $height,
);



my $rect = SDL::Rect->new( -height => $box_height-2 , -width => $box_width-2);
my $rect_color = SDL::Color->new(
	-r => 0x00,
	-g => 0x00,
	-b => 0xff,
);

# build map
$window->fill( $bg, $bg_color );
my $x = 1;
while ($x < $width) {
	$rect->x($x);
	my $y = 1;
	while ($y < $height) {
		$rect->y($y);
		$window->fill( $rect, $rect_color );
		$window->update( $bg );
		$y += $box_height;
	}
	$x += $box_width;
}


my $event = SDL::Event->new;

while (1) {
	while ($event->poll) {
		my $type = $event->type;
		exit if ($type == SDL_QUIT());
		exit if ($type == SDL_KEYDOWN() && $event->key_name eq 'escape');
		#if ( $type == SDL_MOUSEBUTTONDOWN()) {
		if ($type == SDL_MOUSEBUTTONUP()) {
			# left/right?
			print $event->button_x, ", ", $event->button_y, "\n";
		}
	}
}

