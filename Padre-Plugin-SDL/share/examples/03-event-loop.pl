use strict;
use warnings;

use SDL;
use SDL::App;

# after launching this script press the keyboard and whach the console

# this script is using the internal event loop of SDL but as far as I can understand
# this is not a recommended practice.

my $window = SDL::App->new(
	-width => 640,
	-height => 480,
	-depth => 16,
	-title => 'SDL Demo',
);
my %actions = (
	SDL_QUIT() => sub { exit(0) },
	SDL_KEYDOWN() => \&keydown,
);

$window->loop(\%actions);


sub keydown {
	my $event = shift;    # SDL::Event object
	printf("Key Pressed '%s'  name: '%s'\n",$event, $event->key_name());
}
