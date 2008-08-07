use strict;
use warnings;

use Test::More tests => 1;


use File::Temp    qw(tempdir);


my $dir = tempdir( CLEANUP => 1 );
#diag $dir;
$ENV{PADRE_HOME} = $dir;

use Padre;
our $app = Padre->new;
$app->load_config;

use Wx;

my $wxapp = Padre::App->new();

my $frame = $Padre::App::frame;
my $timer = Wx::Timer->new( $frame );
Wx::Event::EVT_TIMER( $frame, -1, sub {
                                      Wx::wxTheApp()->ExitMainLoop;
                                      $frame->Destroy;
                                      #Wx::Event->new(&Wx::wxEVT_COMMAND_BUTTON_CLICKED, 
             #Wx::KeyEvent->new(&Wx::wxEVT_CHAR);
} );
$timer->Start( 500, 1 );

$wxapp->MainLoop;
ok(1);


