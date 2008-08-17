package Padre::Demo::Frame;

use 5.008;
use strict;
use warnings;
use File::Spec         ();
use Wx                 qw(:everything);
use Wx::STC            ();
use Wx::Event          qw(:everything);
use Padre::Demo::App   ();
use Padre::Demo::Frame ();
use base 'Wx::Frame';

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

    return File::Spec->catfile($default_dir, $filename);
}


sub new {
    my ($class) = @_;

    my $self = $class->SUPER::new(
        undef,
        -1,
        'Padre::Demo::App',
        wxDefaultPosition,
        wxDefaultSize,
    );

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
    } );

    return $self;
}

sub on_activate {
   my ($editor, $frame, $event) = @_;

   $output = $editor;
   $frame->EVT_ACTIVATE(sub {});
   return $main->($frame);
}

1;
