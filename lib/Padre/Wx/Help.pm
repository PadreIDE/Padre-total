package Padre::Wx::Help;
use strict;
use warnings;

our $VERSION = '0.10';

use Wx                      qw(:everything);
use Wx::Event               qw(:everything);

sub on_about {
    my ( $self ) = @_;

    my $about = Wx::AboutDialogInfo->new;
    $about->SetName("Padre");
    $about->SetDescription(
        "Perl Application Development and Refactoring Environment\n\n" .
        "Based on Wx.pm $Wx::VERSION and " . wxVERSION_STRING . "\n" .
        "Config at " . Padre->ide->config_dir . "\n"
    );
    $about->SetVersion($Padre::VERSION);
    $about->SetCopyright("(c) 2008 Gabor Szabo");
    $about->SetWebSite("http://padre.perlide.org/");
    $about->AddDeveloper("Gabor Szabo");
    $about->AddDeveloper("Adam Kennedy");

    Wx::AboutBox( $about );
}

sub on_help {
    my ( $self ) = @_;

    if ( not $self->{help} ) {
        $self->{help} = Padre::Pod::Frame->new;
        my $module = Padre::DB->get_last_pod || 'Padre';
        if ( $module ) {
            $self->{help}->{html}->display($module);
        }
    }
    $self->{help}->SetFocus;
    $self->{help}->Show (1);

    return;
}

sub on_context_help {
    my ($self) = @_;

    my $selection = $self->selected_text;

    on_help($self);

    if ( $selection ) {
        $self->{help}->show( $selection );
    }

    return;
}


1;
