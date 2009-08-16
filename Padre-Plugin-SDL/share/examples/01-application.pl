use strict;
use warnings;

use SDL::App;
my $window = SDL::App->new(
	-width => 640,
	-height => 480,
	-depth => 16,
	-title => 'SDL Demo',
);

sleep 2;
