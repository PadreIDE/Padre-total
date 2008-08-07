#!perl
use strict;
use warnings;

$| = 1;

my $app = Demo::App->new;
$app->MainLoop;

package Demo::App;
use strict;
use warnings;
use base 'Wx::App';

our $frame;
sub OnInit {
    $frame = Demo::App::Frame->new;
    $frame->Show( 1 );
}

package Demo::App::Frame;
use strict;
use warnings;
use Wx qw(:everything);
use base 'Wx::Frame';

sub new {
    my ($class) = @_;

    my $self = $class->SUPER::new( undef, -1,
                                 'Demo::App',
                                  wxDefaultPosition,  wxDefaultSize,
                                 );
    my $main = Wx::SplitterWindow->new(
                $self, -1, wxDefaultPosition, wxDefaultSize,
                wxNO_FULL_REPAINT_ON_RESIZE|wxCLIP_CHILDREN );

    my $button = Wx::Button->new( $main, -1, "What is the message?" );
    #$main->SplitHorizontally( $nb, $output, $HEIGHT );
    Wx::Event::EVT_BUTTON( $main, $button, sub {
         my ( $self, $event ) = @_;
         print "printing messsage\n";
         Wx::MessageBox( "This is the message", "Title", wxOK|wxCENTRE, $self );
    });

    Wx::Event::EVT_CLOSE( $self,  sub {
         my ( $self, $event ) = @_;
         $event->Skip;
    });
    return $self;
}

