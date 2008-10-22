package Padre::Wx::FindDialog;

use 5.008;
use strict;
use warnings;

# Find and Replace widget of Padre

use Wx        ();
use Wx::Event qw{ EVT_BUTTON EVT_CHECKBOX };

our $VERSION = '0.10';

my %cbs = (
	case_insensitive => {
		title => "Case &Insensitive",
		row   => 4,
	},
	use_regex        => {
		title => "&Use Regex",
		row   => 5,
	},
	backwards        => {
		title => "Search &Backwards",
		row   => 6,
	},
	close_on_hit     => {
		title => "Close Window on &hit",
		row   => 7,
	},
);

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

	my $dialog = Wx::Dialog->new( $win, -1, "Search", [-1, -1], [500, 300]);

	my $box  = Wx::BoxSizer->new( Wx::wxVERTICAL );
	my @rows;
	foreach my $i ( 0..8 ) {
		push @rows, Wx::BoxSizer->new( Wx::wxHORIZONTAL );
		$box->Add($rows[$i]);
	}

	my @width  = (100, 200);

	my @layout = (
		[
			[ 'Wx::StaticText', undef,              'Find:'],
			[ 'Wx::ComboBox',   '_find_choice_',    $search_term, $config->{search_terms}],
			[ 'Wx::Button',     '_find_',           Wx::wxID_FIND ],
		],
		[
			[ 'Wx::StaticText', undef,              'Replace With:'],
			[ 'Wx::ComboBox',   '_find_choice_',    '', $config->{replace_terms}],
			[ 'Wx::Button',     '_replace_',        '&Replace'],
		],
		[
			[],
			[],
			[ 'Wx::Button',     '_replace_all_',    'Replace &All'],
		]
	);
	Padre::Wx::ModuleStartDialog::build_layout($dialog, \@layout, \@rows, \@width);

#	my $replace_all = Wx::Button->new( $dialog, -1,          'Replace &All', );
	my $cancel      = Wx::Button->new( $dialog, Wx::wxID_CANCEL, '',            );

	#$rows[2]->Add(100, 0, 0, Wx::wxEXPAND, 0);
	#$rows[2]->Add(200, 0, 0, Wx::wxEXPAND, 0);
	#$rows[2]->Add( $replace_all );

	foreach my $field (sort keys %cbs) {
		my $cb = Wx::CheckBox->new( $dialog, -1, $cbs{$field}{title}, [-1, -1], [-1, -1]);
		if ($config->{search}->{$field}) {
		    $cb->SetValue(1);
		}
		$rows[ $cbs{$field}{row} ]->Add($cb);
		EVT_CHECKBOX( $dialog, $cb, sub { $_[0]->{_find_choice_}->SetFocus; });
		$cbs{$field}{cb} = $cb;
	}

	$dialog->{_find_}->SetDefault;
	EVT_BUTTON( $dialog, $dialog->{_find_},        \&find_clicked);
	EVT_BUTTON( $dialog, $dialog->{_replace_},     \&replace_clicked     );
	EVT_BUTTON( $dialog, $dialog->{_replace_all_}, \&replace_all_clicked );
	EVT_BUTTON( $dialog, $cancel,      \&cancel_clicked      );

	$rows[8]->Add(300, 20, 1, Wx::wxEXPAND, 0);
	$rows[8]->Add($cancel);

	$dialog->SetSizer($box);

	$dialog->{_find_choice_}->SetFocus;
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

	my $config = Padre->ide->config;
	foreach my $field (keys %cbs) {
	   $config->{search}->{$field} = $cbs{$field}{cb}->GetValue;
	}

	my $search_term      = $dialog->{_find_choice_}->GetValue;
	my $replace_term     = $dialog->{_replace_choice_}->GetValue;

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
