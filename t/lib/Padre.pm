package t::lib::Padre;

# Common testing logic for Padre

use strict;
use warnings;
use File::Temp;

# By default, load Padre in a controlled environment
BEGIN {
    $ENV{PADRE_HOME} = File::Temp::tempdir( CLEANUP => 1 );
}


sub setup_events {
	my ($frame, $events) = @_;
	foreach my $event (@$events) {
		my $id    = Wx::NewId();
		my $timer = Wx::Timer->new( $frame, $id );
		Wx::Event::EVT_TIMER(
			$frame,
			$id,
			$event->{code}
		);
		$timer->Start( $event->{delay}, 1 );
	}
}

1;
