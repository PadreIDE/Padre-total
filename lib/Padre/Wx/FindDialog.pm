package Padre::Wx::FindDialog;
use strict;
use warnings;

# Find and Replace widget of Padre

use Wx        qw(:everything);
use Wx::Event qw(:everything);

our $VERSION = '0.07';

sub new {
    my ( $class, $win, $config, $args) = @_;

#you can "skip" slots by adding spacers
#$self->{grid_sizer_1} = Wx::GridSizer->new(2, 3, 5, 5);
#$self->{grid_sizer_1}->Add(20, 20, 1, wxEXPAND, 0);    
#$self->{grid_sizer_1}->Add($self->{ButtonDir}, 0, 0, 0);
#$self->{grid_sizer_1}->Add($self->{ButtonQuit}, 0, 0, 0);

    my %search;
    $search{term} = $args->{term} || '';

    my $dialog = Wx::Dialog->new( $win, -1, "Search", [-1, -1], [500, 200]);

    my $box  = Wx::BoxSizer->new(  wxVERTICAL   );
    my $row1 = Wx::BoxSizer->new(  wxHORIZONTAL );
    my $row2 = Wx::BoxSizer->new(  wxHORIZONTAL );
    my $row3 = Wx::BoxSizer->new(  wxHORIZONTAL );
    my $row4 = Wx::BoxSizer->new(  wxHORIZONTAL );

    $box->Add($row1);
    $box->Add($row2);
    $box->Add($row3);
    $box->Add($row4);


    my $find    = Wx::Button->new( $dialog, wxID_FIND,   '',                 );
    #my $replace = Wx::Button->new( $dialog, -1,          'Find and Replace', );
    my $cancel  = Wx::Button->new( $dialog, wxID_CANCEL, '',                 );

    EVT_BUTTON( $dialog, $find,    sub { $dialog->EndModal(wxID_FIND)     } );
    #EVT_BUTTON( $dialog, $replace, sub { $dialog->EndModal('replace')     } );
    EVT_BUTTON( $dialog, $cancel,  sub { $dialog->EndModal(wxID_CANCEL) } );

    my @WIDTH  = (100);
    my @HEIGHT = (200);

    $row1->Add( Wx::StaticText->new( $dialog, -1, 'Find:',         wxDefaultPosition, [$WIDTH[0], -1] ) );
    my $find_choice = Wx::ComboBox->new( $dialog, -1, $search{term}, wxDefaultPosition, wxDefaultSize, $config->{search_terms});
    $row1->Add( $find_choice, 1, wxALL, 3 );
    $row1->Add( $find,        1, wxALL, 3 );

    #$row2->Add( Wx::StaticText->new( $dialog, -1, 'Replace With:', wxDefaultPosition, [$WIDTH[0], -1]) );
    #my $replace_choice = Wx::ComboBox->new( $dialog, -1, '', [-1, -1], [-1, -1], $config->{replace_terms});
    #$row2->Add( $replace_choice, 1, wxALL, 3 );
    #$row2->Add( $replace,        1, wxALL, 3 );


    #my $verbatim = Wx::CheckBox->new( $dialog, -1, "Verbatim", [-1, -1], [-1, -1]);
    #$row2->Add($verbatim);

    my $case_insensitive = Wx::CheckBox->new( $dialog, -1, "Case &Insensitive", [-1, -1], [-1, -1]);
    if ($config->{search}->{case_insensitive}) {
        $case_insensitive->SetValue(1);
    }
    $row3->Add($case_insensitive);
    EVT_CHECKBOX( $dialog, $case_insensitive, sub { $find_choice->SetFocus; });

#    $row2->Add($dir_selector, 1, wxALL, 3);

#    my $path = Wx::StaticText->new( $dialog, -1, '');
#    $row3->Add( $path, 1, wxALL, 3 );
#    EVT_BUTTON( $dialog, $dir_selector, sub {on_pick_project_dir($path, @_) } );
    #wxTE_PROCESS_ENTER
    EVT_TEXT_ENTER($dialog, $find_choice,    sub { $dialog->EndModal(wxID_FIND)    });
    #EVT_TEXT_ENTER($dialog, $replace_choice, sub { $dialog->EndModal('replace') });

    $row4->Add($cancel);

    $dialog->SetSizer($box);
    #$box->SetSizeHints( $self );


    $find_choice->SetFocus;
    my $ret = $dialog->ShowModal;

    if ( $ret eq wxID_CANCEL ) {
        return;
    } elsif ( $ret eq wxID_FIND ) {
    } elsif ( $ret eq 'replace' ) {
        #$search{replace_term}     = $replace_choice->GetValue;
    } else {
        # what the hell?
    }

    $search{term}             = $find_choice->GetValue;
    $search{case_insensitive} = $case_insensitive->GetValue;
    $dialog->Destroy;

    return if not defined $search{term} or $search{term} eq '';

    #unshift @{$config->{search_terms}}, $search_term;
    #my %seen;
    #@{$config->{search_terms}} = grep {!$seen{$_}++} @{$config->{search_terms}};

    return \%search;
}




1;
