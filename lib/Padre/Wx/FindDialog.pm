package Padre::Wx::FindDialog;
use strict;
use warnings;

# Find and Replace widget of Padre

use English        qw(-no_match_vars);
use Wx             qw(:everything);
use Wx::Event      qw(:everything);

our $VERSION = '0.09';

sub dialog {
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

    my %cbs = (
       case_insensitive => {
          title => "Case &Insensitive",
       },
    );
    
    foreach my $field (keys %cbs) {
        my $cb = Wx::CheckBox->new( $dialog, -1, $cbs{$field}{title}, [-1, -1], [-1, -1]);
        if ($config->{search}->{$field}) {
            $cb->SetValue(1);
        }
        $row3->Add($cb);
        EVT_CHECKBOX( $dialog, $cb, sub { $find_choice->SetFocus; });
        $cbs{$field}{cb} = $cb;
    }

    my $use_regex = Wx::CheckBox->new( $dialog, -1, "Use &Regex", [-1, -1], [-1, -1]);
    if ($config->{search}->{use_regex}) {
        $use_regex->SetValue(1);
    }
    $row3->Add($use_regex);
    EVT_CHECKBOX( $dialog, $use_regex, sub { $find_choice->SetFocus; });


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

    foreach my $field (keys %cbs) {
       $search{$field} = $cbs{$field}{cb}->GetValue;
    }

    $search{term}             = $find_choice->GetValue;
    $search{use_regex}        = $use_regex->GetValue;
    $dialog->Destroy;

    return if not defined $search{term} or $search{term} eq '';

    #unshift @{$config->{search_terms}}, $search_term;
    #my %seen;
    #@{$config->{search_terms}} = grep {!$seen{$_}++} @{$config->{search_terms}};

    return \%search;
}

sub on_find {
    my ( $self ) = @_;

    my $config = Padre->ide->get_config;
    my $selection = $self->_get_selection();
    $selection = '' if not defined $selection;

    my $search = Padre::Wx::FindDialog->dialog( $self, $config, {term => $selection} );
    return if not $search;

    $config->{search}->{case_insensitive} = $search->{case_insensitive};
    $config->{search}->{use_regex}        = $search->{use_regex};

    if ($search->{term}) {
        unshift @{$config->{search_terms}}, $search->{term};
        my %seen;
        @{$config->{search_terms}} = grep {!$seen{$_}++} @{$config->{search_terms}};
    }
    if ($search->{replace_term} ) {
        unshift @{$config->{replace_terms}}, $search->{replace_term};
        my %seen;
        @{$config->{replace_terms}} = grep {!$seen{$_}++} @{$config->{replace_terms}};
     }

    _search($self, replace_term => $search->{replace_term});

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

sub _search {
    my ($self, %args) = @_;

    my $config = Padre->ide->get_config;
    my $search_term = $args{search_term} ||= $config->{search_terms}->[0];
    #$args{replace_term}

    my $id   = $self->{notebook}->GetSelection;
    my $page = $self->{notebook}->GetPage($id);
    my $content = $page->GetText;
    my ($from, $to) = $page->GetSelection;
    if ($from < $to) {
        $from++;
    }
    my $last = $page->GetLength();
    my $str  = $page->GetTextRange($from, $last);

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

    my ($start, $end);
    if ($str =~ $regex) {
        $start = $LAST_MATCH_START[0] + $from;
        $end   = $LAST_MATCH_END[0] + $from;
    } else {
        my $str  = $page->GetTextRange(0, $last);
        if ($str =~ $regex) {
            $start = $LAST_MATCH_START[0];
            $end   = $LAST_MATCH_END[0];
        }
    }
    if (not defined $start) {
        return; # not found
    }

    $page->SetSelection($start, $end);

    return;
}



1;
