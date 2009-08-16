use strict;
use warnings;

use SDL::App;
use SDL::Event;
use SDL::Constants;
my $window = SDL::App->new(
	-width => 640,
	-height => 480,
	-depth => 16,
	-title => 'SDL Demo',
);
my $event = SDL::Event->new;
while (1) {
	while ($event->poll) {
		my $type = $event->type;
		exit if ($type == SDL_QUIT);
	}
	$window->sync;
}	

