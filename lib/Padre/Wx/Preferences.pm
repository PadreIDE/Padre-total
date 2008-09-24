package Padre::Wx::Preferences;
use strict;
use warnings;

our $VERSION = '0.10';

use Wx        qw(wxID_OK wxID_CANCEL wxDEFAULT_FRAME_STYLE);
use Wx::Event qw(EVT_BUTTON);

sub new {
    my ( $class, $win, $config ) = @_;

    my $dialog = Wx::Dialog->new( $win, -1, "Configuration", [-1, -1], [550, 200], wxDEFAULT_FRAME_STYLE);

    my $y = 10;
    my $HEIGHT = 30;

    Wx::StaticText->new( $dialog, -1, 'TAB display size (in spaces)', [10, $y], [-1, -1]);
    my $tab_size = Wx::TextCtrl->new( $dialog, -1, $config->{editor}->{tab_size}, [300, $y] , [-1, -1]);
    $tab_size->SetFocus;

    $y += $HEIGHT;
    Wx::StaticText->new( $dialog, -1, 'Max number of modules', [10, $y], [-1, -1]);
    my $max = Wx::TextCtrl->new( $dialog, -1, $config->{DISPLAY_MAX_LIMIT}, [300, $y] , [-1, -1]);

    $y += $HEIGHT;
    Wx::StaticText->new( $dialog, -1, 'Min number of modules', [10, $y], [-1, -1]);
    my $min = Wx::TextCtrl->new( $dialog, -1, $config->{DISPLAY_MIN_LIMIT}, [300, $y] , [-1, -1]);

    $y += $HEIGHT;
    Wx::StaticText->new( $dialog, -1, 'Open files:', [10, $y], [-1, -1]);
    my @values = ($config->{startup}, grep {$_ ne $config->{startup}} qw(new nothing last));
    my $choice = Wx::Choice->new( $dialog, -1, [300, $y], [-1, -1], \@values);

    $y += $HEIGHT;
    my $ok     = Wx::Button->new( $dialog, wxID_OK,     '', [10,  $y] );
    my $cancel = Wx::Button->new( $dialog, wxID_CANCEL, '', [120, $y], $ok->GetSize );
    EVT_BUTTON( $dialog, $ok,     sub { $dialog->EndModal(wxID_OK) } );
    EVT_BUTTON( $dialog, $cancel, sub { $dialog->EndModal(wxID_CANCEL) } );
    $ok->SetDefault;

    if ($dialog->ShowModal == wxID_CANCEL) {
        return;
    }
    $config->{DISPLAY_MAX_LIMIT}  = $max->GetValue;
    $config->{DISPLAY_MIN_LIMIT}  = $min->GetValue;
    $config->{editor}->{tab_size} = $tab_size->GetValue;

    $config->{startup} =  $values[ $choice->GetSelection];

    return;
}

1;
