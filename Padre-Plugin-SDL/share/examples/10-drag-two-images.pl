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


my $img64 = catfile(dirname($0), 'img', 'padre_logo_64x64.png');
my $butterfly_frame = SDL::Surface->new( -name => $img64 );

my $x = int( ($board_width  - $butterfly_frame->width) /2);
my $y = int( ($board_height - $butterfly_frame->height) /2);


my $window = SDL::App->new(
	-width => $board_width,
	-height => $board_height,
	-depth => 16,
	-title => 'SDL Demo',
);


my $butterfly_frame_rect = SDL::Rect->new(
        -height => $butterfly_frame->height(),
        -width  => $butterfly_frame->width(),
        -x      => 0,
        -y      => 0,
);

my $butterfly_location_rect  = SDL::Rect->new(
        -height => $butterfly_frame->height(),
        -width  => $butterfly_frame->width(),
        -x      => $x,
        -y      => $y,
);

my $saved_frame = SDL::Surface->new(
	-width => $butterfly_frame->width(),
	-height => $butterfly_frame->height(),
	-depth => 16, 
	-Amask => '0 but true',
);

my $rect_saved  = SDL::Rect->new(
        -height => $butterfly_frame->height(),
        -width  => $butterfly_frame->width(),
        -x      => $x,
        -y      => $y,
);

redraw_image();

my $event = SDL::Event->new;

my $grab = 0;
while (1) {
	while ($event->poll) {
		my $type = $event->type;
		exit if ($type == SDL_QUIT());
		exit if ($type == SDL_KEYDOWN() && $event->key_name eq 'escape');
		if ( $type == SDL_MOUSEBUTTONDOWN()) {
			print "Mouse down\n";
			printf("Sprite (%s, %s) width %s height %s\n", $butterfly_location_rect->x(), $butterfly_location_rect->y(), $butterfly_location_rect->width, $butterfly_location_rect->height);
			printf("Button     (%s, %s)\n", $event->button_x, $event->button_y);
			if ($butterfly_location_rect->x < $event->button_x and
				$event->button_x < $butterfly_location_rect->x + $butterfly_location_rect->width and
				$butterfly_location_rect->y < $event->button_y and
				$event->button_y < $butterfly_location_rect->y + $butterfly_location_rect->height) {
				# on the object
				$grab = 1;
				print "Grab !!!\n";
			}
		} elsif ( $type == SDL_MOUSEBUTTONUP()) {
			$grab = 0;
			print "Mouse up\n";
		} elsif ( $type == SDL_MOUSEMOTION()) {
			#printf("Motion     (%s, %s)\n", $event->motion_x, $event->motion_y);  # absolute locations
			#printf("Motion rel (%s, %s)\n", $event->motion_xrel, $event->motion_yrel); # how much was the mouse moved
			#printf("Button     (%s, %s)\n", $event->button_x, $event->button_y); # seems to be the same as motion_x
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
		$saved_frame->blit( $butterfly_frame_rect, $window, $butterfly_location_rect );
		$window->update( $butterfly_location_rect );
		$butterfly_location_rect->x($butterfly_location_rect->x + $xrel);
		$butterfly_location_rect->y($butterfly_location_rect->y + $yrel);
	}

	$window->blit( $butterfly_location_rect, $saved_frame, $butterfly_frame_rect );
	#$saved_frame->update( $butterfly_frame_rect );

	$butterfly_frame->blit( $butterfly_frame_rect, $window, $butterfly_location_rect );
	$window->update( $butterfly_location_rect );
}

