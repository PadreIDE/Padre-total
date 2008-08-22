package Padre::Demo;

use 5.008;
use strict;
use warnings;

use base 'Exporter';
use Padre::Demo::App;

our @EXPORT = qw(prompt print_out promp_input_file close_app open_frame);

use Wx                 qw(:everything);
use Wx::STC            ();
use Wx::Event          qw(:everything);

=head1 NAME

Padre::Demo - temporary name of a Zenity clone in wxPerl

=head1 SYNOPIS

As a module:

 use Padre::Demo;

 Padre::Demo->run(\&main);

 sub main {
    my $name = prompt("What is your name?\n");
    print_out("How are you $name today?\n");

    return;
 }

On the command line:

 Not yet available.

=head1 General Options

There are some common option for every dialog

title

window-icon  Not implemented

width

height

=cut

=head1 METHODS

Dialogs

=head2 prompt

Display a text entry dialog

=cut
sub prompt {
    my ($text) = @_;
    my $frame = $Padre::Demo::App::frame;

    my $dialog = Wx::TextEntryDialog->new( $frame, $text, "", '' );
    if ($dialog->ShowModal == wxID_CANCEL) {
        return;
    }   
    my $resp = $dialog->GetValue;
    $dialog->Destroy;
    return $resp;
}


=head2 print_out

=cut
sub print_out {
    my ($text) = @_;
    #my $frame = $Padre::Demo::App::frame;
    my $output = $Padre::Demo::App::output;
    $output->AddText($text);
    #$Padre::Demo::app->Yield;
    #print "x\n";
    return;
}


=head2 promp_input_file

=cut
sub promp_input_file {
    my ($text) = @_;
    my $frame = $Padre::Demo::App::frame;

    my $dialog = Wx::FileDialog->new( $frame, $text, '', "", "*.*", wxFD_OPEN);
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



=head2 open_frame

=cut
sub open_frame {
    my $frame = $Padre::Demo::App::frame;
    my $output = Wx::StyledTextCtrl->new($frame, -1, [-1, -1], [750, 700]);
    $output->SetMarginWidth(1, 0);
    $frame->Show( 1 );
    return $output;
}


=head2 close_app

=cut
sub close_app {
   my $frame = $Padre::Demo::App::frame;
   $frame->Close;
}





sub get_frame {
   return $Padre::Demo::App::frame;
}

$| = 1;

our $main;
our $app;

sub run {
   my ($class, $cb) = @_;
   $main = $cb;
   $app = Padre::Demo::App->new();
   
   $app->MainLoop;
}

1;
