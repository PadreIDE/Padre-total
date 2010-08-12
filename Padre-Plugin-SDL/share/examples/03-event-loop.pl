use strict;
use warnings;
use SDL 2.511;
use SDLx::App;
use SDL::Event;
use SDL::Events;
my $app = SDLx::App->new(
    width  => 640,
    height => 480,
    depth  => 16,
    title  => 'SDL Demo',
);
my %actions =
  ( 
      SDL_QUIT() => sub { print "quit \n"; return 0 }, #return 0 to quit naturally
      SDL_KEYDOWN() => \&keydown, 

   );
$app->add_event_handler ( \&event_handler ); #Set up a callbacks for when to process events and updates
$app->add_show_handler  ( sub {$app->update} );
$app->run();

sub event_handler {
    my $event = shift; #The callback gives us an event to process 
    my $call  = $actions{ $event->type }; #Get our subs from %actions
    return $call->($event) if $call; # return the value of the call'd action if we can
    return 1; #Return a non zero to continue the app
}

sub keydown {
    my $event = shift;    # SDL::Event object
    printf( "Key Pressed '%s' name: '%s'\n",
        $event->key_sym, SDL::Events::get_key_name( $event->key_sym() ) );
    return 1;
}
