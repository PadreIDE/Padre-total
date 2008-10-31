package Padre::Wx::Bookmarks;

use strict;
use warnings;

use List::Util   qw(max);
use Data::Dumper qw(Dumper);

use Padre::Wx;

our $VERSION = '0.14';

sub dialog {
	my ($self, $text) = @_;

	my $box  = Wx::BoxSizer->new( Wx::wxVERTICAL );
	my @rows;
	for my $i (0..3) {
		$rows[$i] = Wx::BoxSizer->new( Wx::wxHORIZONTAL );
		$box->Add($rows[$i]);
	}

	my $title = $text ? "Set Bookmark" : "GoTo Bookmark";
	my $dialog = Wx::Dialog->new( $self, -1, $title, [-1, -1], [-1, -1]);

	if ($text) {
		$dialog->{_widgets_}{entry}  = Wx::TextCtrl->new( $dialog, -1, $text, [-1, -1] , [10 * length $text, -1]);
		$rows[0]->Add( $dialog->{_widgets_}{entry} );
	}


	my $config = Padre->ide->config;
	my @shortcuts = sort keys %{ $config->{bookmarks} };
	my $height = 0;
	my $width  = 25;
	if (@shortcuts) {
		$height = @shortcuts * 27; # should be height of font
		$width  = max( $width,   20 * max (1, map { length($_) } @shortcuts));
	}

	$dialog->{_widgets_}{tb} = Wx::Treebook->new( $dialog, -1, [-1, -1], [$width, $height] );
	$rows[1]->Add( Wx::StaticText->new($dialog, -1, "Existing bookmarks:"));
	$rows[2]->Add( $dialog->{_widgets_}{tb} );

	my $ok = Wx::Button->new( $dialog, Wx::wxID_OK, '' );
	Wx::Event::EVT_BUTTON( $dialog, $ok, sub { $dialog->EndModal(Wx::wxID_OK) } );
	$ok->SetDefault;

	my $cancel  = Wx::Button->new( $dialog, Wx::wxID_CANCEL, '', [-1, -1], $ok->GetSize);
	Wx::Event::EVT_BUTTON( $dialog, $cancel,  sub { $dialog->EndModal(Wx::wxID_CANCEL) } );


	my $delete  = Wx::Button->new( $dialog, Wx::wxID_DELETE, '', [-1, -1], , $ok->GetSize );
	Wx::Event::EVT_BUTTON( $dialog, $delete,  \&on_delete_bookmark );

	$rows[3]->Add( $ok );
	$rows[3]->Add( $cancel );
	if (@shortcuts) {
		$rows[3]->Add( $delete );
	}

	$dialog->SetSizer($box);
	my ($bw, $bh) = $ok->GetSizeWH;

	my $dialog_width = max($width, 2* $bw, 300);
	$dialog->SetSize(-1, -1, $dialog_width, 25 + 40 + $height + $bh); # height of text, entry box

	if ($text) {
		$dialog->{_widgets_}{entry}->SetFocus;
	} else {
		$dialog->{_widgets_}{tb}->SetFocus;
	}


	foreach my $name ( @shortcuts ) {
		my $count = $dialog->{_widgets_}{tb}->GetPageCount;
		my $page = Wx::Panel->new( $dialog->{_widgets_}{tb} );
		$dialog->{_widgets_}{tb}->AddPage( $page, $name, 0, $count );
	}


	my $ret = $dialog->ShowModal;
	if ( $ret eq Wx::wxID_CANCEL ) {
		$dialog->Destroy;
		return;
	}

	if ($text) {
	   my %data;
	   my $shortcut = $dialog->{_widgets_}{entry}->GetValue;
	   $shortcut =~ s/:/ /g; # YAML::Tiny limitation
	   $data{shortcut} = $shortcut;
	   $dialog->Destroy;
	   return ($dialog, \%data);
	} else {
	   return 1;
	}
}

sub on_set_bookmark {
	my ($self, $event) = @_;

	my $pageid = $self->{notebook}->GetSelection();
	my $editor = $self->{notebook}->GetPage($pageid);
	my $line   = $editor->GetCurrentLine;
	my $path   = $self->selected_filename;
	my $file   = File::Basename::basename($path || '');

	my $data = dialog($self, "$file line $line");
	return if not $data;


	#print Dumper $data;

	my $config = Padre->ide->config;
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

	my ($dialog, $data) = dialog($self);
	return if not $data;
print "$dialog\n";
	my $config = Padre->ide->config;
	my $selection = $dialog->{_widgets_}{tb}->GetSelection;
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

	my $dialog = $self;
	my $selection = $dialog->{_widgets_}{tb}->GetSelection;
	my $config = Padre->ide->config;
	my @shortcuts = sort keys %{ $config->{bookmarks} };
	delete $config->{bookmarks}{ $shortcuts[$selection] };
	$dialog->{_widgets_}{tb}->DeletePage($selection);

	return;
}

1;

# Copyright 2008 Gabor Szabo.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.
