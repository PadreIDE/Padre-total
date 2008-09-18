package Padre::Wx::FindDialog;
use strict;
use warnings;

# Find and Replace widget of Padre

use English        qw(-no_match_vars);
use Wx             qw(:everything);
use Wx::Event      qw(:everything);

our $VERSION = '0.09';

my %cbs = (
    case_insensitive => {
        title => "Case &Insensitive",
        row   => 2,
    },
    use_regex        => {
        title => "Use &Regex",
        row   => 3,
    },
    backwards        => {
        title => "Search &Backwards",
        row   => 4,
    },
    close_on_hit     => {
        title => "Close Window on &hit",
        row   => 6,
    },
);


sub on_find {
    my ( $main_window ) = @_;

    my $config = Padre->ide->get_config;
    my $selection = $main_window->_get_selection();
    $selection = '' if not defined $selection;

    Padre::Wx::FindDialog->dialog( $main_window, $config, {term => $selection} );
}


sub dialog {
    my ( $class, $win, $config, $args) = @_;

    my $search_term = $args->{term} || '';

    my $dialog = Wx::Dialog->new( $win, -1, "Search", [-1, -1], [500, 200]);

    my $box  = Wx::BoxSizer->new(  wxVERTICAL   );
    my @rows;
    foreach my $i ( 0..7 ) {
        push @rows, Wx::BoxSizer->new(  wxHORIZONTAL );
        $box->Add($rows[$i]);
    }

    my $find    = Wx::Button->new( $dialog, wxID_FIND,   '',        [-1, -1], [-1, -1]);
    my $replace = Wx::Button->new( $dialog, -1,          'Replace', [-1, -1], [-1, -1]);
    my $cancel  = Wx::Button->new( $dialog, wxID_CANCEL, '',        [-1, -1], [-1, -1]);
    $find->SetDefault;

    EVT_BUTTON( $dialog, $find,    \&find_clicked    );
    EVT_BUTTON( $dialog, $replace, \&replace_clicked );
    EVT_BUTTON( $dialog, $cancel,  \&cancel_clicked  );

    my @WIDTH  = (100);
    my @HEIGHT = (200);

    $rows[0]->Add( Wx::StaticText->new( $dialog, -1, 'Find:',         wxDefaultPosition, [$WIDTH[0], -1] ) );
    my $find_choice = Wx::ComboBox->new( $dialog, -1, $search_term, wxDefaultPosition, wxDefaultSize, $config->{search_terms});
    $rows[0]->Add( $find_choice, 1, wxALL, 3 );
    $rows[0]->Add( $find,        1, wxALL, 3 );

    $rows[1]->Add( Wx::StaticText->new( $dialog, -1, 'Replace With:', wxDefaultPosition, [$WIDTH[0], -1]) );
    my $replace_choice = Wx::ComboBox->new( $dialog, -1, '', [-1, -1], [-1, -1], $config->{replace_terms});
    $rows[1]->Add( $replace_choice, 1, wxALL, 3 );
    $rows[1]->Add( $replace,        1, wxALL, 3 );

    foreach my $field (sort keys %cbs) {
        my $cb = Wx::CheckBox->new( $dialog, -1, $cbs{$field}{title}, [-1, -1], [-1, -1]);
        if ($config->{search}->{$field}) {
            $cb->SetValue(1);
        }
        $rows[ $cbs{$field}{row} ]->Add($cb);
        EVT_CHECKBOX( $dialog, $cb, sub { $find_choice->SetFocus; });
        $cbs{$field}{cb} = $cb;
    }

#    $rows[1]->Add($dir_selector, 1, wxALL, 3);

#    my $path = Wx::StaticText->new( $dialog, -1, '');
#    $rows[2]->Add( $path, 1, wxALL, 3 );
#    EVT_BUTTON( $dialog, $dir_selector, sub {on_pick_project_dir($path, @_) } );
    #wxTE_PROCESS_ENTER
    #EVT_TEXT_ENTER($dialog, $find_choice,    sub { $dialog->EndModal(wxID_FIND)    });
    #EVT_TEXT_ENTER($dialog, $replace_choice, sub { $dialog->EndModal('replace') });
    $rows[7]->Add(300, 20, 1, wxEXPAND, 0);
    $rows[7]->Add($cancel);

    $dialog->SetSizer($box);

    $find_choice->SetFocus;
    $dialog->Show(1);

    $dialog->{_find_choice_}    = $find_choice;
    $dialog->{_replace_choice_} = $replace_choice;

    return;
}

sub cancel_clicked {
    my ($dialog, $event) = @_;

    $dialog->Destroy;

    return;
}

sub replace_clicked {
    my ($dialog, $event) = @_;

    _get_data_from( $dialog ) or return;
    my $regex = _get_regex();
    return if not defined $regex;

    my $config = Padre->ide->get_config;

    # get current search condition and check if they match
    my $main_window = Padre->ide->wx->main_window;
    my $str = $main_window->_get_selection();
    my ($start, $end, @matches) = Padre::Util::get_matches($str, $regex, 0, 0);

    # if they do, replace it
    if (defined $start and $start == 0 and $end == length($str)) {
        my $id   = $main_window->{notebook}->GetSelection;
        my $page = $main_window->{notebook}->GetPage($id);
        #my ($from, $to) = $page->GetSelection;
    
        my $replace_term = $config->{replace_terms}->[0];
        $page->ReplaceSelection($replace_term);
    }

    # if search window is still open, run a search_again on the whole text
    if (not $config->{search}->{close_on_hit}) {
        _search();
    }

    return;
}

sub find_clicked {
    my ($dialog, $event) = @_;

    _get_data_from( $dialog ) or return;
    _search();

    return;
}

sub _get_data_from {
    my ( $dialog ) = @_;

    my $config = Padre->ide->get_config;
    foreach my $field (keys %cbs) {
       $config->{search}->{$field} = $cbs{$field}{cb}->GetValue;
    }

    my $search_term      = $dialog->{_find_choice_}->GetValue;
    my $replace_term     = $dialog->{_replace_choice_}->GetValue;

    if ($config->{search}->{close_on_hit}) {
        $dialog->Destroy;
    }
    return if not defined $search_term or $search_term eq '';

    if ( $search_term ) {
        unshift @{$config->{search_terms}}, $search_term;
        my %seen;
        @{$config->{search_terms}} = grep {!$seen{$_}++} @{$config->{search_terms}};
    }
    if ( $replace_term ) {
        unshift @{$config->{replace_terms}}, $replace_term;
        my %seen;
        @{$config->{replace_terms}} = grep {!$seen{$_}++} @{$config->{replace_terms}};
    }
    return 1;
}

sub on_find_again {
    my $main_window = shift;

    my $term = Padre->ide->get_config->{search_terms}->[0];
    if ( $term ) {
        _search();
    } else {
        on_find( $main_window );
    }
    return;
}

sub on_find_again_reverse {
    my $main_window = shift;

    my $term = Padre->ide->get_config->{search_terms}->[0];
    if ( $term ) {
        _search(rev => 1);
    } else {
        on_find( $main_window );
    }
    return;
}

sub _get_regex {

    my $config = Padre->ide->get_config;

    my $search_term = $config->{search_terms}->[0];
    if ($config->{search}->{use_regex}) {
        $search_term =~ s/\$/\\\$/; # escape $ signs by default so they won't interpolate
    } else {
        $search_term = quotemeta $search_term;
    }

    if ($config->{search}->{case_insensitive})  {
        $search_term = "(?i)$search_term";
    }


    my $regex;
    eval { $regex = qr/$search_term/m };
    if ($@) {
        my $main_window = Padre->ide->wx->main_window;
        Wx::MessageBox("Cannot build regex for '$search_term'", "Search error", wxOK, $main_window);
        return;
    }
    return $regex;
}

sub _search {
    my ( %args ) = @_;
    my $main_window = Padre->ide->wx->main_window;

    my $regex = _get_regex();
    return if not defined $regex;

    my $id   = $main_window->{notebook}->GetSelection;
    my $page = $main_window->{notebook}->GetPage($id);
    my ($from, $to) = $page->GetSelection;
    my $last = $page->GetLength();
    my $str  = $page->GetTextRange(0, $last);

    my $config    = Padre->ide->get_config;
    my $backwards = $config->{search}->{backwards};
    if ($args{rev}) {
       $backwards = not $backwards;
    }
    my ($start, $end, @matches) = Padre::Util::get_matches($str, $regex, $from, $to, $backwards);
    return if not defined $start;

    $page->SetSelection( $start, $end );

    return;
}

1;
