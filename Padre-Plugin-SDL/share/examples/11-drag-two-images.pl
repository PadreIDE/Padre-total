use strict;
use warnings;

use SDL;
use SDL::Constants;
use SDL::App;
use File::Basename        qw(dirname);
use File::Spec::Functions qw(catfile);

# after launching this script try to grab the images with the mouse
# and drag them around the board one by one, try overlapping them

my $board_width = 640;
my $board_height = 480;



my $window = SDL::App->new(
	-width  => $board_width,
	-height => $board_height,
	-depth  => 16,
	-title  => 'SDL Demo',
);

my @layers;
push @layers, {
	surface => SDL::Surface->new(
		-width => $window->width(),
		-height => $window->height(),
		-depth => 16, 
		-Amask => '0 but true',
	),
	rect => SDL::Rect->new(
        -height => $window->height(),
        -width  => $window->width(),
        -x      => 0,
        -y      => 0,
	),
	sprite => SDL::Rect->new(
        -height => $window->height(),
        -width  => $window->width(),
        -x      => 0,
        -y      => 0,
	),
};


my @objects = (
	{
		name => 'Butterfly 64x64',
		path => catfile(dirname($0), 'img', 'padre_logo_64x64.png'),
	},
	{
		name => 'FreeBSD 64x64',
		path => catfile(dirname($0), 'img', 'freebsd-logo.png'),
	}
);

foreach my $o (@objects) {
	my $surface = SDL::Surface->new( -name => $o->{path} );
	my $x = int( ($board_width  - $surface->width) /2);
	my $y = int( ($board_height - $surface->height) /2);

	my $rect = SDL::Rect->new(
		-height => $surface->height(),
		-width  => $surface->width(),
		-x      => 0,
		-y      => 0,
	);

	my $location  = SDL::Rect->new(
		-height => $surface->height(),
		-width  => $surface->width(),
		-x      => $x,
		-y      => $y,
	);

	push @layers, {
		surface => $surface,
		rect    => $rect,
		sprite  => $location,
	};
}



# strategy:
# 1) every move copy all the elements starting from background and
#    then layer by layer each object
# 2) on every move of object X 
#     - restore the image of the background of that image
#     - move to new location
#     - copy the backgrund to safe location
#     - display the obhect in new place
#   What if there are more objects?
#  If they are not overlapping then their images have no interference
# if they are overlapping then one of them is above the other only that is interesting
#  if we want to move the one below we either need to move it to the forground first
#  or we are in serious trouble.

# Strategy 1 seems a lot simpler as implemented below but the screen is flickering


redraw_image();

my $event = SDL::Event->new;

my $grab = 0;
while (1) {
	while ($event->poll) {
		my $type = $event->type;
		exit if ($type == SDL_QUIT());
		exit if ($type == SDL_KEYDOWN() && $event->key_name eq 'escape');
		if ( $type == SDL_MOUSEBUTTONDOWN()) {
			#print "Mouse down\n";
			#printf("Sprite (%s, %s) width %s height %s\n", $butterfly_location_rect->x(), $butterfly_location_rect->y(), $butterfly_location_rect->width, $butterfly_location_rect->height);
			#printf("Button     (%s, %s)\n", $event->button_x, $event->button_y);
			foreach my $i (reverse 1..@layers-1) {
				my $online = $layers[$i]{sprite};
				if ($online->x < $event->button_x and
					$event->button_x < $online->x + $online->width and
					$online->y < $event->button_y and
					$event->button_y < $online->y + $online->height) {

				push @layers, splice(@layers, $i, 1); # put on the top
				# on the object
				$grab = 1;
				print "Grab !!!\n";
				last;
				}
			}
		} elsif ( $type == SDL_MOUSEBUTTONUP()) {
			$grab = 0;
			print "Mouse up\n";
		} elsif ( $type == SDL_MOUSEMOTION()) {
			if ($grab) {
				#print "Mouse moves $event\n";
				#print "Mx ", $event->motion_x, "\n";
				redraw_image($event->motion_xrel, $event->motion_yrel);
			}
		}
	}
}

sub redraw_image {
	my ($xrel, $yrel) = @_;

	if (@_) {
		my $online = $layers[-1]{sprite};
		$online->x($online->x + $xrel);
		$online->y($online->y + $yrel);
	}

	foreach my $thing (@layers) {
		my $surface = $thing->{surface};
		my $offline = $thing->{rect};
		my $online  = $thing->{sprite};
		printf("Thing (%s, %s) width %s height %s\n", $online->x(), $online->y(), $online->width, $online->height);
		$surface->blit( $offline, $window, $online);
		$window->update( $online );
	}
}

