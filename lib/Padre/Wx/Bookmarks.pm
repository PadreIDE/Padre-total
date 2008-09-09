package Padre::Wx::Bookmarks;

use strict;
use warnings;
use Wx        qw(:everything);
use Wx::Event qw(:everything);

our $VERSION = '0.07';

    # by pressing a key show a window to bookmark this page
    # let the user select a free letter, or override an already used letter
    # open window with list of bookmarks
    # allow easily set one of the bookmarks to the current location

sub add_dialog {
    my ($self, $file, $line) = @_;

    my $config = Padre->ide->get_config;

    my $dialog = Wx::Dialog->new( $self, -1, "Set Bookmark", [-1, -1], [-1, -1]);

    my $box  = Wx::BoxSizer->new(  wxVERTICAL   );
    my $row1 = Wx::BoxSizer->new(  wxHORIZONTAL );
    my $row2 = Wx::BoxSizer->new(  wxHORIZONTAL );
    my $row3 = Wx::BoxSizer->new(  wxHORIZONTAL );
    my $row4 = Wx::BoxSizer->new(  wxHORIZONTAL );

    $box->Add($row1);
    $box->Add($row2);
    $box->Add($row3);
    $box->Add($row4);

    $row1->Add( Wx::StaticText->new( $dialog, -1, 'Text:'), 1, wxALL, 3 );
    $row1->Add( Wx::StaticText->new( $dialog, -1, "$file $line"), 1, wxALL, 3 );

    my @shortcuts = keys %{ $config->{bookmarks} };
    my $choice = Wx::ComboBox->new( $dialog, -1, '', [-1, -1], [-1, -1], \@shortcuts);
    $row2->Add( $choice, 1, wxALL, 3);

    my $ok = Wx::Button->new( $dialog, wxID_OK, '');
    EVT_BUTTON( $dialog, $ok, sub { $dialog->EndModal(wxID_OK) });
    $row3->Add($ok);

    my $cancel  = Wx::Button->new( $dialog, wxID_CANCEL, '',                 );
    EVT_BUTTON( $dialog, $cancel,  sub { $dialog->EndModal(wxID_CANCEL) } );
    $row4->Add($cancel);
    $dialog->SetSizer($box);
    $choice->SetFocus;
    EVT_TEXT_ENTER($dialog, $choice,    sub { $dialog->EndModal(wxID_OK) });

    my $ret = $dialog->ShowModal;

    if ( $ret eq wxID_CANCEL ) {
        $dialog->Destroy;
        return;
    }
    my %data;
    $data{shortcut} = $choice->GetValue;

    $dialog->Destroy;

    return \%data;
}


sub on_set_bookmark {
    my ($self, $event) = @_;

    my $pageid = $self->{notebook}->GetSelection();
    my $editor = $self->{notebook}->GetPage($pageid);
    my $line   = $editor->GetCurrentLine;
    my $file   = File::Basename::basename($self->get_current_filename || '');

    my $data = add_dialog($self, $file, $line);
    return if not $data;

    use Data::Dumper;
    print Dumper $data;

    my $config = Padre->ide->get_config;
    my $shortcut = delete $data->{shortcut};
    if (not $shortcut) {
       for my $ch ('a'..'z') {
           if (not $config->{bookmarks}{$ch}) {
               $shortcut = $ch;
               last;
           }
       }
    }
    return if not $shortcut;

    $config->{bookmarks}{$shortcut} = $data;

    return;
}

sub on_goto_bookmark {
    my ($self, $event, $id) = @_;

    my $config = Padre->ide->get_config;

    my $bookmark = $config->{bookmarks}{$id};
    return if not $bookmark;

#    my $pageid = $self->{notebook}->GetSelection();
#    my $editor   = $self->{notebook}->GetPage($pageid);
#    $editor->GotoLine($self->{marker}->{$id});


    return;
}

1;
