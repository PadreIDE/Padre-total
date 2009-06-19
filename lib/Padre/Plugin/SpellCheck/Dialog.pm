#
# This file is part of Padre::Plugin::SpellCheck.
# Copyright (c) 2009 Jerome Quelin, all rights reserved.
#
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
#

package Padre::Plugin::SpellCheck::Dialog;

use warnings;
use strict;

our $VERSION = '1.1.2';

use Class::XSAccessor accessors => {
    _autoreplace => '_autoreplace',  # list of automatic replaces
    _engine      => '_engine',       # pps:engine object
    _error       => '_errorpos',     # first error spotted [ $word, $pos ]
    _label       => '_label',        # label hosting the misspelled word
    _list        => '_list',         # listbox listing the suggestions
    _offset      => '_offset',       # offset of _text within the editor
    _plugin      => '_plugin',       # reference to spellcheck plugin
    _sizer       => '_sizer',        # window sizer
    _text        => '_text',         # text being spellchecked
};

use Padre::Current;
use Padre::Wx ();
use Padre::Util           ('_T');
use Encode;

use base 'Wx::Dialog';


# -- constructor

sub new {
    my ($class, %params) = @_;

    # create object
    my $config = $params{plugin}->config;
    my $self   = $class->SUPER::new(
        Padre::Current->main,
        -1,
        sprintf( _T('Spelling (%s)'), $config->{dictionary} ),
        Wx::wxDefaultPosition,
        Wx::wxDefaultSize,
        Wx::wxDEFAULT_FRAME_STYLE|Wx::wxTAB_TRAVERSAL,
    );
    $self->SetIcon( Wx::GetWxPerlIcon() );
    $self->_error ( $params{error}  );
    $self->_engine( $params{engine} );
    $self->_offset( $params{offset} );
    $self->_text  ( $params{text}   );
    $self->_plugin( $params{plugin} );
    $self->_autoreplace( {} );

    # create dialog
    $self->_create;
    $self->_update;

    return $self;
}

# -- public methods

# -- gui handlers

#
# $self->_on_butclose_clicked;
#
# handler called when the close button has been clicked.
#
sub _on_butclose_clicked {
    my $self = shift;
    $self->Destroy;
}

#
# $self->_on_butignore_all_clicked;
#
# handler called when the ignore all button has been clicked.
#
sub _on_butignore_all_clicked {
    my ($self) = @_;

    my $word = $self->_error->[0];
    $self->_engine->ignore( $word );
    $self->_on_butignore_clicked;
}

#
# $self->_on_butignore_clicked;
#
# handler called when the ignore button has been clicked.
#
sub _on_butignore_clicked {
    my ($self) = @_;

    # remove the beginning of the text, up to after current error
    my $error = $self->_error;
    my ($word, $pos) = @$error;
    $pos += length $word;
    my $text = substr $self->_text, $pos;
    $self->_text( $text );
    my $offset = $self->_offset + $pos;
    $self->_offset( $offset );

    # FIXME: as soon as STC issue is resolved:
    # Include UTF8 characters from ignored word
    # to overall count of UTF8 characters
    # so we can set proper selections
    $self->_engine->_count_utf_chars( $word );

    # try to find next error
    $self->_next;
}

#
# $self->_on_butreplace_all_clicked;
#
# handler called when the replace all button has been clicked.
#
sub _on_butreplace_all_clicked {
    my ($self) = @_;

    # get replacing word
    my $list = $self->_list;
    my $id   = $list->GetNextItem(-1, Wx::wxLIST_NEXT_ALL, Wx::wxLIST_STATE_SELECTED);
    return if $id == -1;
    my $new  = $list->GetItem($id)->GetText;

    # store automatic replacement
    my $old = $self->_error->[0];
    $self->_autoreplace->{$old} = $new;

    # do the replacement
    $self->_on_butreplace_clicked;
}

#
# $self->_on_butreplace_clicked;
#
# handler called when the replace button has been clicked.
#
sub _on_butreplace_clicked {
    my ($self) = @_;
    my $list   = $self->_list;

    # get replacing word
    my $id  = $list->GetNextItem(-1, Wx::wxLIST_NEXT_ALL, Wx::wxLIST_STATE_SELECTED);
    return if $id == -1;
    my $new = $list->GetItem($id)->GetText;

    # actually replace word in editor
    $self->_replace( $new );

    # try to find next error
    $self->_next;
}


# -- private methods

#
# $self->_create;
#
# create the dialog itself.
#
# no params, no return values.
#
sub _create {
    my ($self) = @_;

    # create sizer that will host all controls
    my $sizer = Wx::GridBagSizer->new( 5, 5 );
    $sizer->AddGrowableCol(1);
    $sizer->AddGrowableRow(6);
    $self->_sizer($sizer);

    # create the controls
    $self->_create_labels;
    $self->_create_list;
    $self->_create_buttons;

    # wrap everything in a vbox to add some padding
    my $vbox  = Wx::BoxSizer->new( Wx::wxVERTICAL );
    $vbox->Add( $sizer, 1, Wx::wxEXPAND|Wx::wxALL, 5 );
    $self->SetSizerAndFit($vbox);
    $vbox->SetSizeHints($self);

    # set focus on listbox
    $self->_list->SetFocus;
}

#
# $dialog->_create_buttons;
#
# create the buttons pane.
#
# no params. no return values.
#
sub _create_buttons {
    my ($self) = @_;

    my $ba  = Wx::Button->new( $self, -1, _T('Add to dictionary') );
    my $br  = Wx::Button->new( $self, -1, _T('Replace') );
    my $bra = Wx::Button->new( $self, -1, _T('Replace all') );
    my $bi  = Wx::Button->new( $self, -1, _T('Ignore') );
    my $bia = Wx::Button->new( $self, -1, _T('Ignore all') );
    my $bc  = Wx::Button->new( $self, Wx::wxID_CANCEL, _T('Close') );
    Wx::Event::EVT_BUTTON( $self, $br,  \&_on_butreplace_clicked );
    Wx::Event::EVT_BUTTON( $self, $bra, \&_on_butreplace_all_clicked );
    Wx::Event::EVT_BUTTON( $self, $bi,  \&_on_butignore_clicked );
    Wx::Event::EVT_BUTTON( $self, $bia, \&_on_butignore_all_clicked );
    Wx::Event::EVT_BUTTON( $self, $bc,  \&_on_butclose_clicked );

    my $sizer = $self->_sizer;
    $sizer->Add( $ba,  Wx::GBPosition->new(0,2), Wx::GBSpan->new(1,1), Wx::wxEXPAND );
    $sizer->Add( $br,  Wx::GBPosition->new(2,2), Wx::GBSpan->new(1,1), Wx::wxEXPAND );
    $sizer->Add( $bra, Wx::GBPosition->new(3,2), Wx::GBSpan->new(1,1), Wx::wxEXPAND );
    $sizer->Add( $bi,  Wx::GBPosition->new(4,2), Wx::GBSpan->new(1,1), Wx::wxEXPAND );
    $sizer->Add( $bia, Wx::GBPosition->new(5,2), Wx::GBSpan->new(1,1), Wx::wxEXPAND );
    $sizer->Add( $bc,  Wx::GBPosition->new(7,2), Wx::GBSpan->new(1,1), Wx::wxEXPAND );

    $ba->Disable;
}

#
# $dialog->_create_labels;
#
# create the top labels.
#
# no params. no return values.
#
sub _create_labels {
    my ($self) = @_;
    my $sizer  = $self->_sizer;

    # create the labels...
    my $label   = Wx::StaticText->new( $self, -1, _T('Not in dictionary:') );
    my $labword = Wx::StaticText->new( $self, -1, 'w'x25 );
    $labword->SetBackgroundColour( Wx::Colour->new('#ffaaaa') );
    $labword->Refresh;
    $self->_label($labword);

    # ... and place them
    $sizer->Add( $label,   Wx::GBPosition->new(0,0) );
    $sizer->Add( $labword, Wx::GBPosition->new(0,1), Wx::GBSpan->new(1,1), Wx::wxEXPAND );
}

#
# $dialog->_create_list;
#
# create the suggestions list.
#
# no params. no return values.
#
sub _create_list {
    my ($self) = @_;
    my $sizer  = $self->_sizer;

    my $lab  = Wx::StaticText->new( $self, -1, _T('Suggestions') );
    $sizer->Add( $lab, Wx::GBPosition->new(1,0), Wx::GBSpan->new(1,3), Wx::wxEXPAND );
    my $list = Wx::ListView->new(
        $self,
        -1,
        Wx::wxDefaultPosition,
        Wx::wxDefaultSize,
        Wx::wxLC_SINGLE_SEL,
    );
    Wx::Event::EVT_LIST_ITEM_ACTIVATED($self, $list, \&_on_butreplace_clicked);
    $sizer->Add( $list,
        Wx::GBPosition->new(2,0),
        Wx::GBSpan->new(5,2),
        Wx::wxEXPAND
    );
    $self->_list( $list );
}

#
# dialog->_next;
#
# try to find next mistake, and update dialog to show this new error. if
# no error, display a message and exit.
#
# no params. no return value.
#
sub _next {
    my ($self) = @_;
    my $autoreplace = $self->_autoreplace;

    {
        # try to find next mistake
        my ($word, $pos) = $self->_engine->check( $self->_text );
        $self->_error( [$word, $pos] );

        # no mistake means we're done
        if ( not defined $word ) {
            $self->Destroy;
            $self->GetParent->message( _T( 'Spell check finished.' ), 'Padre' );
            return;
        }

        # check if we have hit a replace all word
        if ( exists $autoreplace->{$word} ) {
            $self->_replace( $autoreplace->{$word} );
            redo; # move on to next error
        }
    }

    # update gui with new error
    $self->_update;
}

#
# $self->_replace( $word );
#
# fix current error by replacing faulty word with $word.
#
# no param. no return value.
#
sub _replace {
    my ($self, $new) = @_;
    my $editor = Padre::Current->editor;

    # replace word in editor
    my $error  = $self->_error;
    my $offset = $self->_offset;
    my ($word, $pos) = @$error;
    my $from = $offset + $pos + $self->_engine->_utf_chars;
    my $to   = $from + length Encode::encode_utf8( $word );
    $editor->SetSelection( $from, $to );
    $editor->ReplaceSelection( $new );

    # FIXME: as soon as STC issue is resolved:
    # Include UTF8 characters from newly added word
    # to overall count of UTF8 characters
    # so we can set proper selections
    $self->_engine->_count_utf_chars( $new );

    # remove the beginning of the text, up to after replaced word
    my $posold = $pos + length $word;
    my $posnew = $pos + length $new;
    my $text = substr $self->_text, $posold;
    $self->_text( $text );
    $offset += $posnew;
    $self->_offset( $offset );
}

#
# self->_update;
#
# update the dialog box with current error.
#
sub _update {
    my ($self) = @_;
    my $error = $self->_error;
    my ($word, $pos) = @$error;

    # update selection in parent window
    my $editor = Padre::Current->editor;
    my $offset = $self->_offset;
    my $from = $offset + $pos + $self->_engine->_utf_chars;
    my $to   = $from + length Encode::encode_utf8( $word );
    $editor->goto_pos_centerize($from);
    $editor->SetSelection( $from, $to );

    # update label
    $self->_label->SetLabel( $word );

    # update list
    my @suggestions = $self->_engine->suggestions( $word );
    my $list = $self->_list;
    $list->DeleteAllItems;
    my $i = 0;
    foreach my $w ( reverse @suggestions ) {
        next unless defined $w;
        my $item = Wx::ListItem->new;
        $item->SetText($w);
        my $idx = $list->InsertItem($item);
        last if ++$i == 25; # FIXME: should be a preference
    }

    # select first item
    my $item = $list->GetItem(0);
    $item->SetState(Wx::wxLIST_STATE_SELECTED);
    $list->SetItem($item);
}


1;

__END__


=head1 NAME

Padre::Plugin::SpellCheck::Dialog - dialog for padre spell check



=head1 DESCRIPTION

This module implements the dialog window that will be used to interact
with the user when mistakes have been spotted.



=head1 PUBLIC METHODS

=head2 Constructor

=over 4

=item my $dialog = PPS::Dialog->new( %params );

Create and return a new dialog window. The following params are needed:

=over 4

=item text => $text

The text being spell checked.

=item offset => $offset

The offset of C<$text> within the editor. 0 if spell checking the whole file.

=item error => [ $word, $pos ]

The first spotted error, on C<$word> (at position C<$pos>), with some
associated C<$suggestions> (a list reference).

=item engine => $engine

The $engine being used (a C<Padre::Plugin::SpellCheck::Engine> object).

=back

=back



=head2 Instance methods

=over 4

=back



=head1 SEE ALSO

For all related information (bug reporting, source code repository,
etc.), refer to L<Padre::Plugin::SpellCheck>.



=head1 AUTHOR

Jerome Quelin, C<< <jquelin@cpan.org> >>



=head1 COPYRIGHT & LICENSE

Copyright (c) 2009 Jerome Quelin, all rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
