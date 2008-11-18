package Padre::Wx::Dialog::Snippets;

use 5.008;
use strict;
use warnings;

# Insert snippets in your code

use Padre::Wx;
use Padre::Wx::Dialog;
use Wx::Locale qw(:default);

our $VERSION = '0.16';

sub get_snipnames {
    my $choices = Padre::DB->find_snipnames;
    return $choices;
}

sub get_layout {
	my ($search_term, $config) = @_;

    my $snippets = get_snipnames;
	my @layout = (
		[
			[ 'Wx::StaticText', undef,              gettext('Class:')],
			[ 'Wx::Choice',     '_find_class_',    [1,2,3]],
		],
		[
			[ 'Wx::StaticText', undef,              gettext('Snippet:')],
			[ 'Wx::Choice',   '_find_snippet_',     $snippets],
		],
		[
			[],
			[],
			[ 'Wx::Button',     '_cancel_',    Wx::wxID_CANCEL],
		],
	);
	return \@layout;
}

sub dialog {
	my ( $class, $win, $args) = @_;

	my $config = Padre->ide->config;
	my $search_term = $args->{term} || '';

	my $layout = get_layout($search_term, $config);
	my $dialog = Padre::Wx::Dialog->new(
		parent => $win,
		title  => gettext("Snippets"),
		layout => $layout,
		width  => [150, 200],
	);

#	$dialog->{_widgets_}{_find_}->SetDefault;
	Wx::Event::EVT_CHOICE( $dialog, $dialog->{_widgets_}{_find_class_},   \&find_class);
	Wx::Event::EVT_CHOICE( $dialog, $dialog->{_widgets_}{_find_snippet_}, \&get_snippet);
	Wx::Event::EVT_BUTTON( $dialog, $dialog->{_widgets_}{_cancel_},       \&cancel_clicked);

	$dialog->{_widgets_}{_find_class_}->SetFocus;

	return $dialog;
}

sub snippets {
	my ($class, $main) = @_;

	my $dialog = $class->dialog( $main, { } );
	$dialog->Show(1);

	return;
}

sub find_class {
	my ($dialog, $event) = @_;

	_get_data_from( $dialog ) or return;

	return;
}

sub get_snippet_text {
	my ($snipno) = @_;

    my $choices = Padre::DB->find_snippets;
    return $choices->[$snipno];
}

sub get_snippet {
	my ($dialog, $event) = @_;

	my $data   = _get_data_from( $dialog ) or return;
    my $snipno = $data->{_find_snippet_};
    my $text   = get_snippet_text($snipno);

	my $win = Padre->ide->wx->main_window;
    my $id  = $win->{notebook}->GetSelection;
    $win->{notebook}->GetPage($id)->ReplaceSelection('');
    my $pos = $win->{notebook}->GetPage($id)->GetCurrentPos;
    $win->{notebook}->GetPage($id)->InsertText( $pos, $text );
#    $win->{notebook}->GetPage($id)->GotoPos( $pos + $length - 1 );	return;
}

sub cancel_clicked {
	my ($dialog, $event) = @_;

	$dialog->Destroy;

	return;
}

sub _get_data_from {
	my ( $dialog ) = @_;

    my $data = $dialog->get_data;

    #print Data::Dumper::Dumper $data;

	return $data;
}

1;

# Copyright 2008 Kaare Rasmussen.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.
