package Padre::Wx::ModuleStartDialog;

use 5.008;
use strict;
use warnings;

# Module::Start widget of Padre

use Wx        ();
use Wx::Event qw{ EVT_BUTTON EVT_CHECKBOX };

our $VERSION = '0.10';

my %cbs = (
);

sub on_start {
	my $main   = shift;
	my $config = Padre->ide->config;

	__PACKAGE__->dialog( $main, $config, { } );
}

sub dialog {
	my ( $class, $win, $config, $args) = @_;

	my $search_term = '';

	my $dialog = Wx::Dialog->new( $win, -1, "Module Start", [-1, -1], [500, 300]);

	my $box  = Wx::BoxSizer->new( Wx::wxVERTICAL );
	my @rows;
	foreach my $i ( 0..8 ) {
		push @rows, Wx::BoxSizer->new( Wx::wxHORIZONTAL );
		$box->Add($rows[$i]);
	}

	my $ok          = Wx::Button->new( $dialog, Wx::wxID_OK,   '', );
	my $cancel      = Wx::Button->new( $dialog, Wx::wxID_CANCEL, '', );
	$ok->SetDefault;

	EVT_BUTTON( $dialog, $ok,          \&ok_clicked          );
	EVT_BUTTON( $dialog, $cancel,      \&cancel_clicked      );

	my @builders = ('Module::Build', 'ExtUtils::MakeMaker', 'Module::Install');
	# list taken from http://search.cpan.org/dist/Module-Build/lib/Module/Build/API.pod
	# even though it should be in http://module-build.sourceforge.net/META-spec.html
	# and we should fetch it from Module::Start or maybe Software::License
	my @licenses = qw(apache artistic artistic_2 bsd gpl lgpl mit mozilla open_source perl restrictive unrestricted);

	my @layout = (
		[
			[ 'Wx::StaticText', undef,              'Module Name:'],
			[ 'Wx::TextCtrl',   '_module_name_',    ''],
		],
		[
			[ 'Wx::StaticText', undef,              'Author:'],
			[ 'Wx::TextCtrl',   '_author_name_',    ''],
		],
		[
			[ 'Wx::StaticText', undef,              'Email:'],
			[ 'Wx::TextCtrl',   '_email_',          ''],
		],
		[
			[ 'Wx::StaticText', undef,              'Builder:'],
			[ 'Wx::ComboBox',   '_builder_choice_', '',       \@builders],
		],
		[
			[ 'Wx::StaticText', undef,              'License:'],
			[ 'Wx::ComboBox',   '_license_choice_', '',       \@licenses],
		],
		[
			[ 'Wx::StaticText', undef,              'Parent Directory:'],
			[ 'Wx::DirPickerCtrl',   '_directory_', ''],
		],
	);
	my @width  = (100, 200);
	build_layout($dialog, \@layout, \@rows, \@width);

	foreach my $field (sort keys %cbs) {
		my $cb = Wx::CheckBox->new( $dialog, -1, $cbs{$field}{title}, [-1, -1], [-1, -1]);
		if ($config->{search}->{$field}) {
		    $cb->SetValue(1);
		}
		$rows[ $cbs{$field}{row} ]->Add($cb);
		#EVT_CHECKBOX( $dialog, $cb, sub { $module_name->SetFocus; });
		$cbs{$field}{cb} = $cb;
	}

	#$rows[8]->Add(300, 20, 1, Wx::wxEXPAND, 0);
	$rows[8]->Add( $ok,);
	$rows[8]->Add($cancel);

	$dialog->SetSizer($box);

	$dialog->{_module_name_}->SetFocus;
	$dialog->Show(1);

	return;
}

sub build_layout {
	my ($dialog, $layout, $rows, $width) = @_;

	foreach my $i (0..@$layout-1) {
		foreach my $j (0..@{$layout->[$i]}-1) {
			my ($class, $name, $arg, @params) = @{ $layout->[$i][$j] };

			my $widget;
			if ($class eq 'Wx::Button') {
				my ($first, $second) = $arg =~ /[a-zA-Z]/ ? (-1, $arg) : ($arg, '');
				$widget = $class->new( $dialog, $first, $second);
			} else {
				$widget = $class->new( $dialog, -1, $arg, Wx::wxDefaultPosition, [$width->[$j], -1], @params );
			}
			$rows->[$i]->Add($widget);
			if ($name) {
				$dialog->{$name} = $widget;
			}
		}
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
	my $regex = '';
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
	my $regex = '';
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

	return;
}


sub _get_data_from {
	my ( $dialog ) = @_;

	my $config = Padre->ide->config;

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


1;
