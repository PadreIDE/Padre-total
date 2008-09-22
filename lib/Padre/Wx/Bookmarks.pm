package Padre::Wx::Bookmarks;

use strict;
use warnings;
use Wx           qw(:everything);
use Wx::Event    qw(:everything);
use List::Util   qw(max);
use Data::Dumper qw(Dumper);

our $VERSION = '0.10';

my $tb;

sub dialog {
	my ($self, $text) = @_;

	my $box  = Wx::BoxSizer->new(  wxVERTICAL   );
	my @rows;
	for my $i (0..3) {
		$rows[$i] = Wx::BoxSizer->new(  wxHORIZONTAL );
		$box->Add($rows[$i]);
	}

	my $title = $text ? "Set Bookmark" : "GoTo Bookmark";
	my $dialog = Wx::Dialog->new( $self, -1, $title, [-1, -1], [-1, -1]);


	my $ok = Wx::Button->new( $dialog, wxID_OK, '' );
	EVT_BUTTON( $dialog, $ok, sub { $dialog->EndModal(wxID_OK) } );
	$ok->SetDefault;

	my $cancel  = Wx::Button->new( $dialog, wxID_CANCEL, '', [-1, -1], $ok->GetSize);
	EVT_BUTTON( $dialog, $cancel,  sub { $dialog->EndModal(wxID_CANCEL) } );


	$rows[3]->Add( $ok );
	$rows[3]->Add( $cancel );


	my ($height, $width) = list_bookmarks($dialog, \@rows, $ok->GetSize);

	my $entry;
	if ($text) {
		$entry  = Wx::TextCtrl->new( $dialog, -1, $text, [-1, -1] , [10 * length $text, -1]);
		$entry->SetFocus;
		$rows[0]->Add( $entry );
	} else {
		$tb->SetFocus;
	}


	$dialog->SetSizer($box);
	my ($bw, $bh) = $ok->GetSizeWH;

	my $dialog_width = max($width, 2* $bw, 300);
	$dialog->SetSize(-1, -1, $dialog_width, 25 + 40 + $height + $bh); # height of text, entry box


	my $ret = $dialog->ShowModal;
	if ( $ret eq wxID_CANCEL ) {
		$dialog->Destroy;
		return;
	}
  
	if ($text) {
	   my %data;
	   my $shortcut = $entry->GetValue;
	   $shortcut =~ s/:/ /g; # YAML::Tiny limitation
	   $data{shortcut} = $shortcut;
	   $dialog->Destroy;
	   return \%data;
	} else {
	   return;
	}
}

sub list_bookmarks {
	my ($dialog, $rows, $button_size) = @_;

	my $config = Padre->ide->get_config;
	my @shortcuts = sort keys %{ $config->{bookmarks} };
	my $height = 0;
	my $width  = 25;

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
	my $path   = $self->get_current_filename;
	my $file   = File::Basename::basename($path || '');

	my $data = dialog($self, "$file line $line");
	return if not $data;


	#print Dumper $data;

	my $config = Padre->ide->get_config;
	my $shortcut = delete $data->{shortcut};
	#my $text     = delete $data->{text};
	
	return if not $shortcut;

	$data->{file}   = $path;
	$data->{line}   = $line;
	$data->{pageid} = $pageid;
	$config->{bookmarks}{$shortcut} = $data;

	return;
}

sub on_goto_bookmark {
	my ($self, $event) = @_;

	dialog($self);

	my $config = Padre->ide->get_config;
	my $selection = $tb->GetSelection;
	my @shortcuts = sort keys %{ $config->{bookmarks} };
	my $bookmark = $config->{bookmarks}{ $shortcuts[$selection] };

	my $file = $bookmark->{file};
	my $line = $bookmark->{line};
	my $pageid = $bookmark->{pageid};

	if (not defined $pageid) {
		# find if the given file is in memory
		$pageid = $self->find_editor_of_file($file);
	}
	if (not defined $pageid) {
		# load the file
		if (-e $file) {
		    $self->setup_editor($file);
		    $pageid = $self->find_editor_of_file($file);
		}
	}

	# go to the relevant editor and row
	if (defined $pageid) {
	   $self->on_nth_pane($pageid);
	   my $page = $self->{notebook}->GetPage($pageid);
	   $page->GotoLine($line);
	}

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
