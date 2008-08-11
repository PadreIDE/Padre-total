#!perl
use strict;
use warnings;

$| = 1;

my $app = Demo::App->new;
$app->MainLoop;

sub main {
   my ($frame, $output) = @_;
   $frame->EVT_ACTIVATE(sub {}); 
   my $name = $frame->prompt("What is your name?\n");
   $output->AddText("How are you $name today?\n");


   return;
}


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
use Wx::Event qw(:everything);

use base 'Wx::Frame';


sub prompt {
    my ($self, $text) = @_;

    my $dialog = Wx::TextEntryDialog->new( $self, $text, "", '' );
    if ($dialog->ShowModal == wxID_CANCEL) {
        return;
    }   
    my $resp = $dialog->GetValue;
    $dialog->Destroy;
    return $resp;
}

sub new {
    my ($class) = @_;

    my $self = $class->SUPER::new( undef, -1,
                                 'Demo::App',
                                  wxDefaultPosition,  wxDefaultSize,
                                 );


use Wx::STC;
#use Wx::StyledTextCtrl;
    my $editor = Wx::StyledTextCtrl->new($self, -1, [-1, -1], [750, 700]);
    $editor->SetMarginWidth(1, 0);

    EVT_ACTIVATE($self, sub {main::main($_[0], $editor) });


#    my $button = Wx::Button->new( $self, -1, "Run" );
#    Wx::Event::EVT_BUTTON( $self, $button, sub {
#         my ( $self, $event ) = @_;
#         print "preparing to popup window...\n";
#         Wx::MessageBox( "This is the smell of an Onion", "Title", wxOK|wxCENTRE, $self );
#    });
#    $self->SetSize($button->GetSizeWH);

    Wx::Event::EVT_CLOSE( $self,  sub {
         my ( $self, $event ) = @_;
         $event->Skip;
    });
    return $self;
}

