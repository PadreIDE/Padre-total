use strict;
use warnings;
use SDL 2.511;
use SDL::Rect;
use SDL::Events;
use SDLx::App;
my $app = SDLx::App->new(
    width  => 640,
    height => 480,
    depth  => 16,
    title  => 'SDL Demo',
);
my $rect = SDL::Rect->new( 0, 0, 20, 10 );
my $bg_color = [ 0, 0, 0,    0 ];
my $color    = [ 0, 0, 0xff, 0xff ];
my $velocity = 1.0;

sub draw_frame {
    my ( $app, %args ) = @_;
    $app->draw_rect( $args{bg},   $args{bg_color} );
    $app->draw_rect( $args{rect}, $args{rect_color} );
    $app->update();
}

sub move_handler {
    my $dt = shift;
    if ( $rect->x == 0 ) { $velocity = 1; }
    elsif ( $rect->x + $rect->w == $app->w ) { $velocity = -1; }
    $rect->x( $rect->x + $velocity * $dt );
    $rect->y( ( $rect->x / $app->w ) * $app->h );
}

sub show_handler {
    draw_frame(
        $app,
        bg         => undef,
        bg_color   => $bg_color,
        rect       => $rect,
        rect_color => $color,
    );
}

sub event_handler {
    my $event = shift;
    return 0 if $event->type == SDL_QUIT;
    return 1;
}
$app->add_event_handler( \&event_handler );
$app->add_move_handler( \&move_handler );
$app->add_show_handler( \&show_handler );
$app->run();
