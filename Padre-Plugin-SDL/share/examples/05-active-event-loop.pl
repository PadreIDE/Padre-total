use strict;
use warnings;

use SDL;
use SDL::App;
use SDL::Color;
use SDL::Rect;

# after launching this script press the keyboard and whach the console

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


my $event = SDL::Event->new;

while (1) {
	while ($event->poll) {
		my $type = $event->type;
		exit if ($type == SDL_QUIT());
		exit if ($type == SDL_KEYDOWN() && $event->key_name eq 'escape');
		if ( $type == SDL_KEYDOWN() ) {
			my $name = $event->key_name;
			if ($name =~ m/^(left|right|down|up)$/ ) {
				$dir = $name;
			}
		}
	}

	if ($dir eq 'right') {
		$x++;
	} elsif ($dir eq 'left') {
		$x--;
	} elsif ($dir eq 'up') {
		$y--;
	} elsif ($dir eq 'down') {
		$y++;
	} else {
		# huh ?
	}

	$rect->x( $x );
	$rect->y( $y );
        draw_frame( $window,
                bg         => $bg,   
		bg_color   => $bg_color,
		rect       => $rect, 
		rect_color => $color,
	);
}

