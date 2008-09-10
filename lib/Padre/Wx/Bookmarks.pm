package Padre::Wx::Bookmarks;

use strict;
use warnings;
use Wx         qw(:everything);
use Wx::Event  qw(:everything);
use List::Util qw(max);

our $VERSION = '0.07';

    # by pressing a key show a window to bookmark this page
    # let the user select a free letter, or override an already used letter
    # open window with list of bookmarks
    # allow easily set one of the bookmarks to the current location

#    EVT_TEXT_ENTER($dialog, $choice,    sub { $dialog->EndModal(wxID_OK) });
#    EVT_COMBOBOX($dialog, $choice, sub {print "c\n" });

my $tb;

sub add_dialog {
    my ($self, $file, $line) = @_;

    my $box  = Wx::BoxSizer->new(  wxVERTICAL   );
    my @rows;
    for my $i (0..3) {
       $rows[$i] = Wx::BoxSizer->new(  wxHORIZONTAL );
       $box->Add($rows[$i]);
    }


    my $dialog = Wx::Dialog->new( $self, -1, "Set Bookmark", [-1, -1], [-1, -1]);

    my $text = "$file line: $line";
    my $entry  = Wx::TextCtrl->new( $dialog, -1, $text, [-1, -1] , [10 * length $text, -1]);
    $entry->SetFocus;
    $rows[0]->Add( $entry );

    my $height = 0;
    my $width  = 25;

    my $ok = Wx::Button->new( $dialog, wxID_OK, '' );
    EVT_BUTTON( $dialog, $ok, sub { $dialog->EndModal(wxID_OK) } );
    $ok->SetDefault;

    my $cancel  = Wx::Button->new( $dialog, wxID_CANCEL, '', [-1, -1], $ok->GetSize);
    EVT_BUTTON( $dialog, $cancel,  sub { $dialog->EndModal(wxID_CANCEL) } );


    $rows[3]->Add( $ok );
    $rows[3]->Add( $cancel );

    ($height, $width) = list_bookmarks($dialog, $height, $width, \@rows, $ok->GetSize);

    $dialog->SetSizer($box);
    my ($bw, $bh) = $ok->GetSizeWH;

    my $dialog_width = max($width, 2* $bw, 300);
    $dialog->SetSize(-1, -1, $dialog_width, 25 + 40 + $height + $bh); # height of text, entry box


    my $ret = $dialog->ShowModal;
    if ( $ret eq wxID_CANCEL ) {
       $dialog->Destroy;
       return;
    }
  
    my %data;
    my $shortcut = $entry->GetValue;
    $shortcut =~ s/:/ /g; # YAML::Tiny limitation

    #$data{text}     = $text;
    $data{shortcut} = $shortcut;
    $dialog->Destroy;

    return \%data;
}

sub list_bookmarks {
    my ($dialog, $height, $width, $rows, $button_size) = @_;

    my $config = Padre->ide->get_config;
    my @shortcuts = sort keys %{ $config->{bookmarks} };
    if (@shortcuts) {
        $height = @shortcuts * 27; # should be height of font
        $width  = max( $width,   20 * max (1, map { length($_) } @shortcuts));
        $tb = Wx::Treebook->new( $dialog, -1, [-1, -1], [$width, $height] );
        foreach my $name ( @shortcuts ) {
            my $count = $tb->GetPageCount;
            my $page = Wx::Panel->new( $tb );
            $tb->AddPage( $page, $name, 0, $count );
        }
        $rows->[1]->Add( Wx::StaticText->new($dialog, -1, "Existing bookmarks:"));
        $rows->[2]->Add( $tb );

        my $delete  = Wx::Button->new( $dialog, wxID_DELETE, '', [-1, -1], $button_size );
        EVT_BUTTON( $dialog, $delete,  \&on_delete_bookmark );
        $rows->[3]->Add( $delete );
    }

   return ($height, $width);
}

sub on_set_bookmark {
    my ($self, $event) = @_;

    my $pageid = $self->{notebook}->GetSelection();
    my $editor = $self->{notebook}->GetPage($pageid);
    my $line   = $editor->GetCurrentLine;
    my $file   = File::Basename::basename($self->get_current_filename || '');

    my $data = add_dialog($self, $file, $line);
    return if not $data;

    #use Data::Dumper;
    #print Dumper $data;

    my $config = Padre->ide->get_config;
    my $shortcut = delete $data->{shortcut};
    #my $text     = delete $data->{text};
    
    return if not $shortcut;

    $data->{file}   = $file;
    $data->{line}   = $line;
    $data->{pageid} = $pageid;
    $config->{bookmarks}{$shortcut} = $data;

    return;
}

sub on_goto_bookmark {
    my ($self, $event) = @_;

    my $config = Padre->ide->get_config;

#    show_dialog($self);

    #my $bookmark = $config->{bookmarks}{$id};
    #return if not $bookmark;

#    my $pageid = $self->{notebook}->GetSelection();
#    my $editor   = $self->{notebook}->GetPage($pageid);
#    $editor->GotoLine($self->{marker}->{$id});


    return;
}
sub on_delete_bookmark {
    my ($self, $event) = @_;

    my $selection = $tb->GetSelection;
    my $config = Padre->ide->get_config;
    my @shortcuts = sort keys %{ $config->{bookmarks} };
    delete $config->{bookmarks}{ $shortcuts[$selection] };
    $tb->DeletePage($selection);

    return;
}

1;
