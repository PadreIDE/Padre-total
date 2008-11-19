package Padre::Wx::Dialog::Snippets;

use 5.008;
use strict;
use warnings;

# Insert snippets in your code

use Padre::Wx;
use Padre::Wx::Dialog;
use Wx::Locale qw(:default);

our $VERSION = '0.17';

sub get_layout {
    my ($config) = @_;

    my $cats = Padre::DB->find_snipclasses;
    unshift @$cats, gettext('All');
    my $snippets = Padre::DB->find_snipnames;

    my @layout = (
        [ [ 'Wx::StaticText', undef, gettext('Class:') ],   [ 'Wx::Choice', '_find_cat_',     $cats ], ],
        [ [ 'Wx::StaticText', undef, gettext('Snippet:') ], [ 'Wx::Choice', '_find_snippet_', $snippets ], ],
        [ [], [ 'Wx::Button', '_insert_', gettext('&Insert') ], [ 'Wx::Button', '_cancel_', Wx::wxID_CANCEL ], ],
    );
    return \@layout;
}

sub dialog {
    my ( $class, $win, $args ) = @_;

    my $config = Padre->ide->config;

    my $layout = get_layout($config);
    my $dialog = Padre::Wx::Dialog->new(
        parent => $win,
        title  => gettext("Snippets"),
        layout => $layout,
        width  => [ 150, 200 ],
    );

    Wx::Event::EVT_CHOICE( $dialog, $dialog->{_widgets_}{_find_cat_}, \&find_category );
    Wx::Event::EVT_BUTTON( $dialog, $dialog->{_widgets_}{_insert_}, \&get_snippet );
    Wx::Event::EVT_BUTTON( $dialog, $dialog->{_widgets_}{_cancel_}, \&cancel_clicked );

    $dialog->{_widgets_}{_find_cat_}->SetFocus;
    $dialog->{_widgets_}{_insert_}->SetDefault;

    return $dialog;
}

sub snippets {
    my ( $class, $main ) = @_;

    my $dialog = $class->dialog( $main, {} );
    $dialog->Show(1);

    return;
}

sub _get_catno {
    my ( $dialog ) = @_;

    my $data     = $dialog->get_data;
    my $catno    = $data->{_find_cat_};
    return $catno ? @{ Padre::DB->find_snipclasses }[$catno-1] : '';
}

sub find_category {
    my ( $dialog, $event ) = @_;

    my $cat = _get_catno($dialog);
    my $snippets = Padre::DB->find_snipnames($cat);
    my $field    = $dialog->{_widgets_}{_find_snippet_};
    $field->Clear;
    $field->AppendItems($snippets);
    $field->SetSelection(0);

    return;
}

sub get_snippet_text {
    my ( $cat, $snipno ) = @_;

    my $choices = Padre::DB->find_snippets($cat);
    return $choices->[$snipno];
}

sub get_snippet {
    my ( $dialog, $event ) = @_;

    my $data   = $dialog->get_data or return;
    my $cat = _get_catno($dialog);
    my $snipno = $data->{_find_snippet_};
    my $text   = get_snippet_text( $cat, $snipno );
    my $win = Padre->ide->wx->main_window;
    my $id  = $win->{notebook}->GetSelection;
    $win->{notebook}->GetPage($id)->ReplaceSelection('');
    my $pos = $win->{notebook}->GetPage($id)->GetCurrentPos;
    $win->{notebook}->GetPage($id)->InsertText( $pos, $text );

    return;
}

sub cancel_clicked {
    my ( $dialog, $event ) = @_;

    $dialog->Destroy;

    return;
}

1;

# Copyright 2008 Kaare Rasmussen.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.
