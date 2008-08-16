package Padre::Demo;
use strict;
use warnings;

use base 'Exporter';

our @EXPORT = qw(prompt print_out promp_input_file);
sub prompt {
   my $frame = $Padre::Demo::App::frame;
   $frame->prompt(@_);
}
sub print_out {
   my $frame = $Padre::Demo::App::frame;
   $frame->print_out(@_);
}
sub promp_input_file {
   my $frame = $Padre::Demo::App::frame;
   $frame->promp_input_file(@_);
}


$| = 1;

my $main;

sub run {
   my ($class, $cb) = @_;
   $main = $cb;
   my $app = Padre::Demo::App->new();
   
   $app->MainLoop;
}


package Padre::Demo::App;
use strict;
use warnings;
use base 'Wx::App';


our $frame;
sub OnInit {
    $frame = Padre::Demo::App::Frame->new;


    $frame->Show( 1 );
}

package Padre::Demo::App::Frame;
use strict;
use warnings;

use Wx qw(:everything);
use Wx::Event qw(:everything);

use base 'Wx::Frame';

use File::Spec::Functions qw(catfile);

my $output;

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

sub print_out {
    my ($self, $text) = @_;
    $output->AddText($text);
    return;
}

sub promp_input_file {
    my ($self, $text) = @_;

    my $dialog = Wx::FileDialog->new( $self, $text, '', "", "*.*", wxFD_OPEN);
    if ($^O !~ /win32/i) {
       $dialog->SetWildcard("*");
    }
    if ($dialog->ShowModal == wxID_CANCEL) {
        return;
    }
    my $filename = $dialog->GetFilename;
    my $default_dir = $dialog->GetDirectory;

    return catfile($default_dir, $filename);
}


sub new {
    my ($class) = @_;

    my $self = $class->SUPER::new( undef, -1,
                                 'Padre::Demo::App',
                                  wxDefaultPosition,  wxDefaultSize,
                                 );


use Wx::STC;
#use Wx::StyledTextCtrl;
    my $editor = Wx::StyledTextCtrl->new($self, -1, [-1, -1], [750, 700]);
    $editor->SetMarginWidth(1, 0);


    EVT_ACTIVATE($self, sub {on_activate($editor, @_) });


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

sub on_activate {
   my ($editor, $frame, $event) = @_;

   $output = $editor;
   $frame->EVT_ACTIVATE(sub {});
   return $main->($frame);
}

1;