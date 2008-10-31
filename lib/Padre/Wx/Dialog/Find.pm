package Padre::Wx::Dialog::Find;

use 5.008;
use strict;
use warnings;

# Find and Replace widget of Padre

use Padre::Wx;
use Padre::Wx::Dialog;

our $VERSION = '0.14';

my @cbs = qw(case_insensitive use_regex backwards close_on_hit);

sub get_layout {
	my ($search_term, $config) = @_;

	my @layout = (
		[
			[ 'Wx::StaticText', undef,              'Find:'],
			[ 'Wx::ComboBox',   '_find_choice_',    $search_term, $config->{search_terms}],
			[ 'Wx::Button',     '_find_',           Wx::wxID_FIND ],
		],
		[
			[ 'Wx::StaticText', undef,              'Replace With:'],
			[ 'Wx::ComboBox',   '_replace_choice_',    '', $config->{replace_terms}],
			[ 'Wx::Button',     '_replace_',        '&Replace'],
		],
		[
			[],
			[],
			[ 'Wx::Button',     '_replace_all_',    'Replace &All'],
		],
		[
			['Wx::CheckBox',    'case_insensitive', 'Case &Insensitive',    ($config->{search}->{case_insensitive} ? 1 : 0) ],
		],
		[
			['Wx::CheckBox',    'use_regex',        '&Use Regex',           ($config->{search}->{use_regex} ? 1 : 0) ],
		],
		[
			['Wx::CheckBox',    'backwards',        'Search &Backwards',    ($config->{search}->{backwards} ? 1 : 0) ],
		],
		[
			['Wx::CheckBox',    'close_on_hit',     'Close Window on &hit', ($config->{search}->{close_on_hit} ? 1 : 0) ],
		],
		[
			[],
			[],
			[ 'Wx::Button',     '_cancel_',    Wx::wxID_CANCEL],
		],
	);
	return \@layout;
}


sub on_find {
	my $main   = shift;
	my $config = Padre->ide->config;
	my $text   = $main->selected_text;
	$text = '' if not defined $text;

	# TODO: if selection is more than one lines then consider it as the limit
	# of the search and replace and not as the string to be used

	__PACKAGE__->dialog( $main, $config, { term => $text } );
}


sub dialog {
	my ( $class, $win, $config, $args) = @_;

	my $search_term = $args->{term} || '';

	my $layout = get_layout($search_term, $config);
	my $dialog = Padre::Wx::Dialog->new(
		std    => [$win, -1, "Search", [-1, -1], [440, 220]],
		layout => $layout,
		width  => [150, 200],
	);

	foreach my $cb (@cbs) {
		Wx::Event::EVT_CHECKBOX( $dialog, $dialog->{_widgets_}{$cb}, sub { $_[0]->{_widgets_}{_find_choice_}->SetFocus; });
	}
	$dialog->{_widgets_}{_find_}->SetDefault;
	Wx::Event::EVT_BUTTON( $dialog, $dialog->{_widgets_}{_find_},        \&find_clicked);
	Wx::Event::EVT_BUTTON( $dialog, $dialog->{_widgets_}{_replace_},     \&replace_clicked     );
	Wx::Event::EVT_BUTTON( $dialog, $dialog->{_widgets_}{_replace_all_}, \&replace_all_clicked );
	Wx::Event::EVT_BUTTON( $dialog, $dialog->{_widgets_}{_cancel_},      \&cancel_clicked      );

	$dialog->{_widgets_}{_find_choice_}->SetFocus;
	$dialog->Show(1);

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

	my $config = Padre->ide->config;
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

	my $data = $dialog->get_data;

	#print Data::Dumper::Dumper $data;

	my $config = Padre->ide->config;
	foreach my $field (@cbs) {
	   $config->{search}->{$field} = $data->{$field};
	}
	my $search_term      = $data->{_find_choice_};
	my $replace_term     = $data->{_replace_choice_};

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

sub on_find_next {
	my $main_window = shift;

	my $term = Padre->ide->config->{search_terms}->[0];
	if ( $term ) {
		_search();
	} else {
		on_find( $main_window );
	}
	return;
}

sub on_find_previous {
	my $main_window = shift;

	my $term = Padre->ide->config->{search_terms}->[0];
	if ( $term ) {
		_search(rev => 1);
	} else {
		on_find( $main_window );
	}
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
		Wx::MessageBox("Cannot build regex for '$search_term'", "Search error", Wx::wxOK, $main_window);
		return;
	}
	return $regex;
}

sub _search {
	my ( %args ) = @_;
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

1;

# Copyright 2008 Gabor Szabo.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.
