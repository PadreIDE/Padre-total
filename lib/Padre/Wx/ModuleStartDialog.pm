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
	my $cancel      = Wx::Button->new( $dialog, Wx::wxID_CANCEL, '',            );
	$ok->SetDefault;

	EVT_BUTTON( $dialog, $ok,          \&ok_clicked          );
	EVT_BUTTON( $dialog, $cancel,      \&cancel_clicked      );

	my @WIDTH  = (100);
	my @HEIGHT = (200);

	$rows[0]->Add( Wx::StaticText->new( $dialog, -1, 'Module Name:', Wx::wxDefaultPosition, [$WIDTH[0], -1] ) );
    my $module_name = Wx::TextCtrl->new( $dialog, -1 , '', [-1, -1], [200, -1]);
	$rows[0]->Add( $module_name, 1, Wx::wxALL, 3 );

	$rows[1]->Add( Wx::StaticText->new( $dialog, -1, 'Author:', Wx::wxDefaultPosition, [$WIDTH[0], -1]) );
    my $author_name = Wx::TextCtrl->new( $dialog, -1 , '', [-1, -1], [200, -1]);
	$rows[1]->Add( $author_name, 1, Wx::wxALL, 3 );

	$rows[2]->Add( Wx::StaticText->new( $dialog, -1, 'Email:', Wx::wxDefaultPosition, [$WIDTH[0], -1]) );
    my $email = Wx::TextCtrl->new( $dialog, -1 , '', [-1, -1], [200, -1]);
	$rows[2]->Add( $email, 1, Wx::wxALL, 3 );

	my @builders = ('Module::Build', 'ExtUtils::MakeMaker', 'Module::Install');
	$rows[3]->Add( Wx::StaticText->new( $dialog, -1, 'Builder:',  Wx::wxDefaultPosition, [$WIDTH[0], -1] ) );
	my $builder_choice = Wx::ComboBox->new( $dialog, -1, '', Wx::wxDefaultPosition, Wx::wxDefaultSize, \@builders);
	$rows[3]->Add( $builder_choice, 1, Wx::wxALL, 3 );

	my @licenses = qw(perl retricted);
	$rows[4]->Add( Wx::StaticText->new( $dialog, -1, 'License:',         Wx::wxDefaultPosition, [$WIDTH[0], -1] ) );
	my $license_choice = Wx::ComboBox->new( $dialog, -1, '', Wx::wxDefaultPosition, Wx::wxDefaultSize, \@licenses);
	$rows[4]->Add( $license_choice, 1, Wx::wxALL, 3 );

	$rows[5]->Add( Wx::StaticText->new( $dialog, -1, 'Directory:',         Wx::wxDefaultPosition, [$WIDTH[0], -1] ) );
	my $directory = Wx::DirPickerCtrl->new( $dialog, -1);
	$rows[5]->Add( $directory, 1, Wx::wxALL, 3 );

	foreach my $field (sort keys %cbs) {
		my $cb = Wx::CheckBox->new( $dialog, -1, $cbs{$field}{title}, [-1, -1], [-1, -1]);
		if ($config->{search}->{$field}) {
		    $cb->SetValue(1);
		}
		$rows[ $cbs{$field}{row} ]->Add($cb);
		EVT_CHECKBOX( $dialog, $cb, sub { $module_name->SetFocus; });
		$cbs{$field}{cb} = $cb;
	}

	#$rows[8]->Add(300, 20, 1, Wx::wxEXPAND, 0);
	$rows[8]->Add( $ok,);
	$rows[8]->Add($cancel);

	$dialog->SetSizer($box);

	$module_name->SetFocus;
	$dialog->Show(1);

	$dialog->{_module_name_} = $module_name;
	$dialog->{_author_name_} = $author_name;
	$dialog->{_email_} = $email;

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

sub find_clicked {
	my ($dialog, $event) = @_;

	_get_data_from( $dialog ) or return;

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


1;
