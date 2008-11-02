package Padre::Wx::Dialog::Bookmarks;

use strict;
use warnings;

use List::Util   qw(max);
use Data::Dumper qw(Dumper);

use Padre::Wx;
use Padre::Wx::Dialog;

our $VERSION = '0.14';

sub get_layout {
	my ($text, $shortcuts) = @_;
	
	my @layout;
	if ($text) {
		push @layout, [['Wx::TextCtrl', 'entry', $text]];
	}
	push @layout,
		[
			['Wx::StaticText', undef, "Existing bookmarks:"],
		],
		[
			['Wx::Treebook',   'tb', $shortcuts],
		],
		[
			['Wx::Button',     'ok',     Wx::wxID_OK],
			['Wx::Button',     'cancel', Wx::wxID_CANCEL],
		];

	if (@$shortcuts) {
		push @{ $layout[-1] }, 
			['Wx::Button',     'delete', Wx::wxID_DELETE];
	}
	return \@layout;
}


sub dialog {
	my ($class, $main, $text) = @_;

	my $title = $text ? "Set Bookmark" : "GoTo Bookmark";
	my $config = Padre->ide->config;
	my @shortcuts = sort keys %{ $config->{bookmarks} };

	my $layout = get_layout($text, \@shortcuts);
	my $dialog = Padre::Wx::Dialog->new(
		parent   => $main,
		title    => $title,
		size     => [360, 220],
		layout   => $layout,
		width    => [300, 50],
		top_left => [5, 5],
	);
	if ($dialog->{_widgets_}{entry}) {
		$dialog->{_widgets_}{entry}->SetSize(10 * length $text, -1);
	}

#	foreach my $b (qw(ok cancel delete)) {
#		print "$b ", join (':', $dialog->{_widgets_}{ok}->GetSizeWH), "\n";
#	}
	Wx::Event::EVT_BUTTON( $dialog, $dialog->{_widgets_}{ok},      sub { $dialog->EndModal(Wx::wxID_OK) } );
	Wx::Event::EVT_BUTTON( $dialog, $dialog->{_widgets_}{cancel},  sub { $dialog->EndModal(Wx::wxID_CANCEL) } );
	$dialog->{_widgets_}{ok}->SetDefault;

	if ($dialog->{_widgets_}{delete}) {
		Wx::Event::EVT_BUTTON( $dialog, $dialog->{_widgets_}{delete},  \&on_delete_bookmark );
	}

#	my ($bw, $bh) = $ok->GetSizeWH;

#	my $height = 0;
#	my $width  = 25;
#	if (@shortcuts) {
#		$height = @shortcuts * 27; # should be height of font
#		$width  = max( $width,   20 * max (1, map { length($_) } @shortcuts));
#	}
#
#	my $dialog_width = max($width, 2* $bw, 300);
#	$dialog->SetSize(-1, -1, $dialog_width, 25 + 40 + $height + $bh); # height of text, entry box
#
	if ($text) {
		$dialog->{_widgets_}{entry}->SetFocus;
	} else {
		$dialog->{_widgets_}{tb}->SetFocus;
	}

	return $dialog;
}

sub show_modal {
	my ($dialog) = @_;
	my $ret = $dialog->ShowModal;
	if ( $ret eq Wx::wxID_CANCEL ) {
		$dialog->Destroy;
		return;
	} else {
		return 1;
	}
}

sub _get_data {
	my ($dialog) = @_;

	my %data;
	my $shortcut = $dialog->{_widgets_}{entry}->GetValue;
	$shortcut =~ s/:/ /g; # YAML::Tiny limitation
	$data{shortcut} = $shortcut;
	$dialog->Destroy;
	return ($dialog, \%data);
}

sub set_bookmark {
	my ($class, $main) = @_;

	my $pageid   = $main->{notebook}->GetSelection();
	my $editor   = $main->{notebook}->GetPage($pageid);
	my $line     = $editor->GetCurrentLine;
	my $path     = $main->selected_filename;
	my $file     = File::Basename::basename($path || '');

	my $dialog   = $class->dialog($main, "$file line $line");
	return if not show_modal($dialog);
	
	my $data     = _get_data($dialog);

	my $config   = Padre->ide->config;
	my $shortcut = delete $data->{shortcut};
	#my $text     = delete $data->{text};
	
	return if not $shortcut;

	$data->{file}   = $path;
	$data->{line}   = $line;
	$data->{pageid} = $pageid;
	$config->{bookmarks}{$shortcut} = $data;

	return;
}

sub goto_bookmark {
	my ($class, $main) = @_;

	my $dialog    = $class->dialog($main);
	return if show_modal($dialog);
	
	my $config    = Padre->ide->config;
	my $selection = $dialog->{_widgets_}{tb}->GetSelection;
	my @shortcuts = sort keys %{ $config->{bookmarks} };
	my $bookmark  = $config->{bookmarks}{ $shortcuts[$selection] };

	my $file      = $bookmark->{file};
	my $line      = $bookmark->{line};
	my $pageid    = $bookmark->{pageid};

	if (not defined $pageid) {
		# find if the given file is in memory
		$pageid = $main->find_editor_of_file($file);
	}
	if (not defined $pageid) {
		# load the file
		if (-e $file) {
			$main->setup_editor($file);
			$pageid = $main->find_editor_of_file($file);
		}
	}

	# go to the relevant editor and row
	if (defined $pageid) {
	   $main->on_nth_pane($pageid);
	   my $page = $main->{notebook}->GetPage($pageid);
	   $page->GotoLine($line);
	}

	return;
}

sub on_delete_bookmark {
	my ($dialog, $event) = @_;

	my $selection = $dialog->{_widgets_}{tb}->GetSelection;
	my $config    = Padre->ide->config;
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
