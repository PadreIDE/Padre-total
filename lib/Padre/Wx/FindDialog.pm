package Padre::Wx::FindDialog;
use strict;
use warnings;

# Find and Replace widget of Padre

use Wx        qw(:everything);
use Wx::Event qw(:everything);

our $VERSION = '0.06';

sub new {
    my ( $class, $win, $config, $args) = @_;

    my %search;
    $search{term} = $args->{term} || '';

    my $dialog = Wx::Dialog->new( $win, -1, "Search", [-1, -1], [-1, -1]);

    my $box  = Wx::BoxSizer->new(  wxVERTICAL );
    my $row1 = Wx::BoxSizer->new(  wxHORIZONTAL );
    my $row2 = Wx::BoxSizer->new(  wxHORIZONTAL );
    my $row3 = Wx::BoxSizer->new(  wxHORIZONTAL );
    my $row4 = Wx::BoxSizer->new(  wxHORIZONTAL );

    $box->Add($row1);
    $box->Add($row2);
    $box->Add($row3);
    $box->Add($row4);

    my $choice = Wx::ComboBox->new( $dialog, -1, $search{term}, [-1, -1], [-1, -1], $config->{search_terms});
    $row1->Add( $choice, 1, wxALL, 3);

    #my $verbatim = Wx::CheckBox->new( $dialog, -1, "Verbatim", [-1, -1], [-1, -1]);
    #$row2->Add($verbatim);

    #my $case_insensitive = Wx::CheckBox->new( $dialog, -1, "Case Insensitive", [-1, -1], [-1, -1]);
    #$row2->Add($case_insensitive);


#    $row2->Add($dir_selector, 1, wxALL, 3);

#    my $path = Wx::StaticText->new( $dialog, -1, '');
#    $row3->Add( $path, 1, wxALL, 3 );
#    EVT_BUTTON( $dialog, $dir_selector, sub {on_pick_project_dir($path, @_) } );
    #wxTE_PROCESS_ENTER
    EVT_TEXT_ENTER($dialog, $choice, sub { $dialog->EndModal(wxID_OK) });

    my $ok     = Wx::Button->new( $dialog, wxID_OK,     '');
    my $cancel = Wx::Button->new( $dialog, wxID_CANCEL, '');
    EVT_BUTTON( $dialog, $ok,     sub { $dialog->EndModal(wxID_OK)     } );
    EVT_BUTTON( $dialog, $cancel, sub { $dialog->EndModal(wxID_CANCEL) } );
    $row4->Add($cancel, 1, wxALL, 3);
    $row4->Add($ok,     1, wxALL, 3);

    $dialog->SetSizer($box);
    #$box->SetSizeHints( $self );

    $choice->SetFocus;
    if ($dialog->ShowModal == wxID_CANCEL) {
        return;
    }
    $search{term} = $choice->GetValue;
    $dialog->Destroy;

    return if not defined $search{term} or $search{term} eq '';

    #unshift @{$config->{search_terms}}, $search_term;
    my %seen;
    @{$config->{search_terms}} = grep {!$seen{$_}++} @{$config->{search_terms}};

    return \%search;
}




1;
