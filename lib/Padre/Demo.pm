package Padre::Demo;

use 5.008;
use strict;
use warnings;

use base 'Exporter';
use File::Spec;

our @EXPORT = qw(
                 entry
                 file_selector
                 choice

                 print_out close_app open_frame display_text);

use Wx                 qw(:everything);
use Wx::STC            ();
use Wx::Event          qw(:everything);

=head1 NAME

Padre::Demo - temporary name of a Zenity clone in wxPerl

=head1 SYNOPIS

As a module:

 use Padre::Demo;

 my $name = prompt("What is your name?\n");
 print_out("How are you $name today?\n");


On the command line try

 wxer --help

=head1 General Options

There are some common option for every dialog

title

window-icon  NA

width        NA

height       NA

=cut

=head1 METHODS

Dialogs

=head2 entry

Display a text entry dialog

=cut
sub entry {
    my ( %args ) = @_;

    %args = (
              title   => '',
              prompt  => '',
              default => '',
              %args);

    my $dialog = Wx::TextEntryDialog->new( undef, $args{prompt}, $args{title}, $args{default} );
    if ($dialog->ShowModal == wxID_CANCEL) {
        return;
    }
    my $resp = $dialog->GetValue;
    $dialog->Destroy;
    return $resp;
}


=head2 file_selector

=cut
sub file_selector {
    my ( %args ) = @_;
    %args = (
                title => '',
                %args);

    my $dialog = Wx::FileDialog->new( undef, $args{title}, '', "", "*.*", wxFD_OPEN);
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

sub choice {
    my ( %args ) = @_;
    %args = (
                title   => '',
                message => '',
                choices => [],

                %args);

    my $dialog = Wx::MultiChoiceDialog->new( undef, $args{message}, $args{title}, $args{choices});
    if ($dialog->ShowModal == wxID_CANCEL) {
        return;
    }
    return map {$args{choices}[$_]} $dialog->GetSelections;
}



=head2 print_out

=cut
sub print_out {
    my ($output, $text) = @_;
    $output->AddText($text);
    #$Padre::Demo::app->Yield;
    return;
}

sub display_text {
    my ($text) = @_;
    my $title = '';
    Wx::MessageBox( $text, $title, wxOK|wxCENTRE);

}




=head2 open_frame

=cut
sub open_frame {
    my $frame = Padre::Demo::Frame->new;
    my $output = Wx::StyledTextCtrl->new($frame, -1, [-1, -1], [750, 700]);
    $output->SetMarginWidth(1, 0);
    $frame->Show( 1 );
    return $output;
}


=head2 close_app

=cut
sub close_app {
#   $frame->Close;
}


$| = 1;

our $main;
our $app;

1;
