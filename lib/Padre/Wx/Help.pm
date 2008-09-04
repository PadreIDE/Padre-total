package Padre::Wx::Help;
use strict;
use warnings;

our $VERSION = '0.07';

use Wx                      qw(:everything);
use Wx::Event               qw(:everything);

sub on_about {
    my ( $self ) = @_;

    Wx::MessageBox( 
        "Perl Application Development and Refactoring Environment\n" .
        "Padre $Padre::VERSION, (c) 2008 Gabor Szabo\n" .
        "Using Wx v$Wx::VERSION, binding " . wxVERSION_STRING,
        "About Padre", wxOK|wxCENTRE, $self );
}

sub on_help {
    my ( $self ) = @_;

    if ( not $self->{help} ) {
        $self->{help} = Padre::Pod::Frame->new;
        my $module = Padre->ide->get_current('pod') || 'Padre';
        if ($module) {
            $self->{help}->{html}->display($module);
        }
    }
    $self->{help}->SetFocus;
    $self->{help}->Show (1);

    return;
}

sub on_context_help {
    my ($self) = @_;

    my $selection = $self->_get_selection();

    on_help($self);

    if ($selection) {
        $self->{help}->show($selection);
    }

    return;
}


1;
