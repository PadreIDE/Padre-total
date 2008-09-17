package Padre::Wx::FindDialog;
use strict;
use warnings;

# Find and Replace widget of Padre

use English        qw(-no_match_vars);
use Wx             qw(:everything);
use Wx::Event      qw(:everything);

our $VERSION = '0.09';

my $main;
my $find_choice;
my %cbs = (
    case_insensitive => {
        title => "Case &Insensitive",
    },
    use_regex        => {
        title => "Use &Regex",
    },
    backwards        => {
        title => "Search &Backwards",
    },
    close_on_hit     => {
        title => "Close Window on &hit",
    },
);


sub on_find {
    my ( $self ) = @_;
    $main = $self;

    my $config = Padre->ide->get_config;
    my $selection = $self->_get_selection();
    $selection = '' if not defined $selection;

    Padre::Wx::FindDialog->dialog( $self, $config, {term => $selection} );
}


sub dialog {
    my ( $class, $win, $config, $args) = @_;

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
    $find->SetDefault;
    #my $replace = Wx::Button->new( $dialog, -1,          'Find and Replace', );
    my $cancel  = Wx::Button->new( $dialog, wxID_CANCEL, '',                 );

    EVT_BUTTON( $dialog, $find,    \&find_clicked   );
    #EVT_BUTTON( $dialog, $replace, \&replace_clicked );
    EVT_BUTTON( $dialog, $cancel,  \&cancel_clicked );

    my @WIDTH  = (100);
    my @HEIGHT = (200);

    $row1->Add( Wx::StaticText->new( $dialog, -1, 'Find:',         wxDefaultPosition, [$WIDTH[0], -1] ) );
    $find_choice = Wx::ComboBox->new( $dialog, -1, $search{term}, wxDefaultPosition, wxDefaultSize, $config->{search_terms});
    $row1->Add( $find_choice, 1, wxALL, 3 );
    $row1->Add( $find,        1, wxALL, 3 );

    #$row2->Add( Wx::StaticText->new( $dialog, -1, 'Replace With:', wxDefaultPosition, [$WIDTH[0], -1]) );
    #my $replace_choice = Wx::ComboBox->new( $dialog, -1, '', [-1, -1], [-1, -1], $config->{replace_terms});
    #$row2->Add( $replace_choice, 1, wxALL, 3 );
    #$row2->Add( $replace,        1, wxALL, 3 );


    #my $verbatim = Wx::CheckBox->new( $dialog, -1, "Verbatim", [-1, -1], [-1, -1]);
    #$row2->Add($verbatim);

    
    foreach my $field (sort keys %cbs) {
        my $cb = Wx::CheckBox->new( $dialog, -1, $cbs{$field}{title}, [-1, -1], [-1, -1]);
        if ($config->{search}->{$field}) {
            $cb->SetValue(1);
        }
        $row3->Add($cb);
        EVT_CHECKBOX( $dialog, $cb, sub { $find_choice->SetFocus; });
        $cbs{$field}{cb} = $cb;
    }

#    $row2->Add($dir_selector, 1, wxALL, 3);

#    my $path = Wx::StaticText->new( $dialog, -1, '');
#    $row3->Add( $path, 1, wxALL, 3 );
#    EVT_BUTTON( $dialog, $dir_selector, sub {on_pick_project_dir($path, @_) } );
    #wxTE_PROCESS_ENTER
    #EVT_TEXT_ENTER($dialog, $find_choice,    sub { $dialog->EndModal(wxID_FIND)    });
    #EVT_TEXT_ENTER($dialog, $replace_choice, sub { $dialog->EndModal('replace') });
    $row4->Add(300, 20, 1, wxEXPAND, 0);
    $row4->Add($cancel);

    $dialog->SetSizer($box);
    #$box->SetSizeHints( $self );


    $find_choice->SetFocus;
    $dialog->Show(1);

    return;
}

sub cancel_clicked {
    my ($self, $event) = @_;

    $self->Destroy;

    return;
}

#    } elsif ( $ret eq 'replace' ) {
#        #$search{replace_term}     = $replace_choice->GetValue;

sub find_clicked {
    my ($dialog, $event) = @_;

    my $config = Padre->ide->get_config;
    foreach my $field (keys %cbs) {
       $config->{search}->{$field} = $cbs{$field}{cb}->GetValue;
    }

    my %search;
    $search{term}             = $find_choice->GetValue;
    if ($config->{search}->{close_on_hit}) {
        $dialog->Destroy;
    }

    return if not defined $search{term} or $search{term} eq '';

    #unshift @{$config->{search_terms}}, $search_term;
    #my %seen;
    #@{$config->{search_terms}} = grep {!$seen{$_}++} @{$config->{search_terms}};

    if ($search{term}) {
        unshift @{$config->{search_terms}}, $search{term};
        my %seen;
        @{$config->{search_terms}} = grep {!$seen{$_}++} @{$config->{search_terms}};
    }
    if ($search{replace_term} ) {
        unshift @{$config->{replace_terms}}, $search{replace_term};
        my %seen;
        @{$config->{replace_terms}} = grep {!$seen{$_}++} @{$config->{replace_terms}};
     }

    _search($main, replace_term => $search{replace_term});

    return;
}


sub on_find_again {
    my $self = shift;
    my $term = Padre->ide->get_config->{search_terms}->[0];
    if ( $term ) {
        _search($self);
    } else {
        $self->on_find;
    }
    return;
}
sub on_find_again_reverse {
    my $self = shift;
    my $term = Padre->ide->get_config->{search_terms}->[0];
    if ( $term ) {
        _search($self, rev => 1);
    } else {
        $self->on_find;
    }
    return;
}

sub _get_regex {
    my ($self, $args) = @_;

    my $config = Padre->ide->get_config;

    my $search_term = $args->{search_term} ||= $config->{search_terms}->[0];
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
        Wx::MessageBox("Cannot build regex for '$search_term'", "Search error", wxOK, $self);
        return;
    }
    return $regex;
}

sub _search {
    my ($self, %args) = @_;

    my $regex = _get_regex($self, \%args);
    return if not defined $regex;

    #$args{replace_term}
    my $config = Padre->ide->get_config;

    my $id   = $self->{notebook}->GetSelection;
    my $page = $self->{notebook}->GetPage($id);
    my ($from, $to) = $page->GetSelection;
    my $last = $page->GetLength();
    my $str  = $page->GetTextRange(0, $last);

    my $backwards = $config->{search}->{backwards};
    if ($args{rev}) {

       $backwards = not $backwards;
    }
    my ($start, $end, @matches) = Padre::Util::get_matches($str, $regex, $from, $to, $backwards);
    return if not defined $start;
    #print "$from - $to;  $start - $end\n";

    $page->SetSelection( $start, $end );

    return;
}

1;
