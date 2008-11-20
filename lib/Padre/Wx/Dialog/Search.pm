package Padre::Wx::Dialog::Search;

use 5.008;
use strict;
use warnings;

# Incremental search for padre

use Padre::Wx;
use Wx::Locale qw(:default);

our $VERSION = '0.17';

my $backward = 0;   # whether to search up or down
my $restart  = 1;   # whether to search from start
my %wx;	            # all the wx widgets


#
# search($direction);
#
# initiate/continue searching in $direction.
#
sub search {
	my ($dir) = @_;
	$backward = $dir eq 'previous';
	
	# create panel if needed
	_create_panel() unless defined $wx{panel};

	my $main    = Padre->ide->wx->main_window;
	my $auimngr = $main->manager;
	my $pane    = $auimngr->GetPane('find');
	if ( $pane->IsShown ) {
		_find();
	} else {
		_show_panel();
	}
}


# -- Private subs

sub _find {
	my $main  = Padre->ide->wx->main_window;

	my $page  = Padre::Documents->current->editor;
	my $last  = $page->GetLength();
	my $text  = $page->GetTextRange(0, $last);
	my $what  = quotemeta $wx{entry}->GetValue;
	my $regex = $wx{case}->GetValue ? qr/$what/ : qr/$what/i;
	my ($from, $to) = $restart
		? (0, $last)
		: $page->GetSelection;
	$restart = 0;

	# search and highlight
	my ($start, $end, @matches) =
		Padre::Util::get_matches($text, $regex, $from, $to, $backward);
	if ( defined $start ) {
		$page->SetSelection($start, $end);
		$wx{entry}->SetBackgroundColour(Wx::wxWHITE);
	} else {
		$wx{entry}->SetBackgroundColour(Wx::wxRED);
	}
}


# -- GUI related subs

#
# _create_panel();
#
# create find panel in aui manager.
#
sub _create_panel {
	my $main = Padre->ide->wx->main_window;

	# the panel and the boxsizer to place controls
	my $panel = Wx::Panel->new($main, -1);
	my $hbox  = Wx::BoxSizer->new(Wx::wxHORIZONTAL);
	$panel->SetSizerAndFit($hbox);
	$wx{panel} = $panel;

	# close button
	$wx{close} = Wx::BitmapButton->new(
		$panel, -1,
		Padre::Wx::tango( 'emblems', 'emblem-unreadable.png' )
	);
	Wx::Event::EVT_BUTTON($main, $wx{close}, \&_hide_panel);

	# search area
	$wx{label} = Wx::StaticText->new($panel, -1, gettext('Find:'));
	$wx{entry} = Wx::TextCtrl->new($panel, -1, '');
	$wx{entry}->SetMinSize( Wx::Size->new(25*$wx{entry}->GetCharWidth, -1) );
	Wx::Event::EVT_CHAR(       $wx{entry}, \&_on_key_pressed  );
	Wx::Event::EVT_TEXT($main, $wx{entry}, \&_on_entry_changed);

	# case sensitivity
	$wx{case} = Wx::CheckBox->new($panel, -1, gettext('Case sensitive'));
	Wx::Event::EVT_CHECKBOX($main, $wx{case}, \&_on_case_checked);
	
	# place all controls
	foreach my $w ( qw{ close label entry case } ) {
		$hbox->Add(10,0);
		$hbox->Add($wx{$w});
	}

	# make sure the panel is high enough
	$panel->Fit;

	# manage the pane in aui
	$main->manager->AddPane($panel,
		Wx::AuiPaneInfo->new->Name( 'find' )
		->Bottom
		->CaptionVisible(0)
		->Layer(1)
		->Fixed
		->Show(0)
	);
}


#
# _hide_panel();
#
# remove find panel.
#
sub _hide_panel {
	my $main = Padre->ide->wx->main_window;

	my $auimngr = $main->manager;
	my $pane    = $auimngr->GetPane('find');
	$pane->Hide;
	$auimngr->Update;
}


#
# _show_panel();
#
# force visibility of find panel.
#
sub _show_panel {
	my $main = Padre->ide->wx->main_window;

	# show panel
	my $auimngr = $main->manager;
	my $pane    = $auimngr->GetPane('find');
	$pane->Show;
	$auimngr->Update;

	# direct input to search
	$wx{entry}->SetFocus;
}


# -- Event handlers

#
# _on_case_checked()
#
# called when the "case sensitive" checkbox has changed value. in that case,
# we'll restart searching from the start of the document.
#
sub _on_case_checked {
	$restart = 1;
	_find();
}


#
# _on_entry_changed()
#
# called when the entry content has changed (keyboard or other mean). in that
# case, we'll start searching from the start of the document.
#
sub _on_entry_changed {
	$restart = 1;
	_find();
}


#
# _on_key_pressed()
#
# called when a key is pressed in the entry. used to trap escape so we abort
# search, otherwise dispatch event up-stack.
#
sub _on_key_pressed {
	my ($entry, $event) = @_;
	my $mod  = $event->GetModifiers || 0;
	my $code = $event->GetKeyCode;

	# remove the bit ( Wx::wxMOD_META) set by Num Lock being pressed on Linux
	$mod = $mod & (Wx::wxMOD_ALT + Wx::wxMOD_CMD + Wx::wxMOD_SHIFT);

	if ( $code == Wx::WXK_ESCAPE ) {
		_hide_panel();
		return;
	}

	$event->Skip(1);
}

1;

# Copyright 2008 Gabor Szabo.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.
