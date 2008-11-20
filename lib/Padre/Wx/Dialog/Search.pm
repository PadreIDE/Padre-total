package Padre::Wx::Dialog::Search;

use 5.008;
use strict;
use warnings;

# Find widget of Padre

use Padre::Wx;
use Padre::Wx::Dialog;
use Wx::Locale qw(:default);

our $VERSION = '0.17';

my %wx;

my @cbs = qw(case_insensitive use_regex backwards close_on_hit);


#
# search($direction);
#
# initiate/continue searching in $direction.
#
sub search {
	my ($dir) = @_;
	
	# create panel if needed
	_create_panel() unless defined $wx{panel};

    my $main    = Padre->ide->wx->main_window;
	my $auimngr = $main->manager;
	my $pane    = $auimngr->GetPane('find');
    if ( $pane->IsShown ) {
        $dir eq 'next'
            ? _find_next()
            : _find_previous();
    } else {
        _show_panel();
    }

    return;

    my $class;
	my $config = Padre->ide->config;
	# for Quick Find
	if ( $config->{experimental} ) {
		# check if is checked
		if ( $main->{menu}->{experimental_quick_find}->IsChecked ) {
			my $text = $main->selected_text;
			if ( $text ) {
				unshift @{$config->{search_terms}}, $text;
			}
		}
	}

	my $term = $config->{search_terms}->[0];
	if ( $term ) {
		$class->search();
	} else {
		$class->find( $main );
	}
	return;
}

sub find_previous {
	my ($class, $main) = @_;

	my $term = Padre->ide->config->{search_terms}->[0];
	if ( $term ) {
		$class->search(rev => 1);
	} else {
		$class->find( $main );
	}
	return;
}


sub cancel_clicked {
	my ($dialog, $event) = @_;

	$dialog->Destroy;

	return;
}

sub replace_all_clicked {
	my ($dialog, $event) = @_;

	_get_data_from( $dialog ) or return;
	my $regex = _get_regex();
	return if not defined $regex;

	my $config      = Padre->ide->config;
	my $main_window = Padre->ide->wx->main_window;

	my $id   = $main_window->{notebook}->GetSelection;
	my $page = $main_window->{notebook}->GetPage($id);
	my $last = $page->GetLength();
	my $str  = $page->GetTextRange(0, $last);

	my $replace_term = $config->{replace_terms}->[0];
	$replace_term =~ s/\\t/\t/g;

	my ($start, $end, @matches) = Padre::Util::get_matches($str, $regex, 0, 0);
	$page->BeginUndoAction;
	foreach my $m (reverse @matches) {
		$page->SetTargetStart($m->[0]);
		$page->SetTargetEnd($m->[1]);
		$page->ReplaceTarget($replace_term);
	}
	$page->EndUndoAction;

	return;
}

sub replace_clicked {
	my ($dialog, $event) = @_;

	_get_data_from( $dialog ) or return;
	my $regex = _get_regex();
	return if not defined $regex;

	my $config = Padre->ide->config;

	# get current search condition and check if they match
	my $main_window = Padre->ide->wx->main_window;
	my $str         = $main_window->selected_text;
	my ($start, $end, @matches) = Padre::Util::get_matches($str, $regex, 0, 0);

	# if they do, replace it
	if (defined $start and $start == 0 and $end == length($str)) {
		my $id   = $main_window->{notebook}->GetSelection;
		my $page = $main_window->{notebook}->GetPage($id);
		#my ($from, $to) = $page->GetSelection;
	
		my $replace_term = $config->{replace_terms}->[0];
		$replace_term =~ s/\\t/\t/g;
		$page->ReplaceSelection($replace_term);
	}

	# if search window is still open, run a search_again on the whole text
	if (not $config->{search}->{close_on_hit}) {
		__PACKAGE__->search();
	}

	return;
}

sub find_clicked {
	my ($dialog, $event) = @_;

	_get_data_from( $dialog ) or return;
	__PACKAGE__->search();

	return;
}

sub _get_regex {
	my %args = @_;

	my $config = Padre->ide->config;

	my $search_term = $args{search_term} || $config->{search_terms}->[0];
	return $search_term if defined $search_term and 'Regexp' eq ref $search_term;

	if ($config->{search}->{use_regex}) {
		$search_term =~ s/\$/\\\$/; # escape $ signs by default so they won't interpolate
	} else {
		$search_term = quotemeta $search_term;
	}

	if ($config->{search}->{case_insensitive})  {
		$search_term =~ s/^(\^?)/$1(?i)/;
	}

	my $regex;
	eval { $regex = qr/$search_term/m };
	if ($@) {
		my $main_window = Padre->ide->wx->main_window;
		Wx::MessageBox(sprintf(gettext("Cannot build regex for '%s'"), $search_term), gettext("Search error"), Wx::wxOK, $main_window);
		return;
	}
	return $regex;
}

sub __old_search {
	my ( $class, %args ) = @_;

	my $main_window = Padre->ide->wx->main_window;

	my $regex = _get_regex(%args);
	return if not defined $regex;

	my $id   = $main_window->{notebook}->GetSelection;
	my $page = $main_window->{notebook}->GetPage($id);
	my ($from, $to) = $page->GetSelection;
	my $last = $page->GetLength();
	my $str  = $page->GetTextRange(0, $last);

	my $config    = Padre->ide->config;
	my $backwards = $config->{search}->{backwards};
	if ($args{rev}) {
	   $backwards = not $backwards;
	}
	my ($start, $end, @matches) = Padre::Util::get_matches($str, $regex, $from, $to, $backwards);
	return if not defined $start;

	$page->SetSelection( $start, $end );

	return;
}

# -- Private subs

sub _find_next {
	my $main  = Padre->ide->wx->main_window;

    my $page = Padre::Documents->current->editor;
	my ($from, $to) = $page->GetSelection;
	my $last = $page->GetLength();
	my $str  = $page->GetTextRange(0, $last);
    my $regex = quotemeta $wx{entry}->GetValue;
	my ($start, $end, @matches) = Padre::Util::get_matches($str, $regex, $from, $to, 0);

	return if not defined $start;
	$page->SetSelection( $start, $end );
}

sub _find_previous {
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
	$wx{label} = Wx::StaticText->new($panel, -1, 'Find:');
	$wx{entry}  = Wx::TextCtrl->new($panel, -1, '');
	$wx{entry}->SetMinSize( Wx::Size->new(25*$wx{entry}->GetCharWidth, -1) );
    Wx::Event::EVT_CHAR($wx{entry}, \&_on_key_pressed);

    # place all controls
    foreach my $w ( qw{ close label entry } ) {
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
		->Resizable(0)
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
# force visibility of find panel. create panel if needed.
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
