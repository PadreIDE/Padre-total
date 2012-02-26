package Padre::Plugin::SpellCheck::Checker;

use warnings;
use strict;

use Class::XSAccessor {
	replace   => 1,
	accessors => {
		_autoreplace => '_autoreplace', # list of automatic replaces
		_engine      => '_engine',      # pps:engine object
		                                # _error       => '_errorpos',    # first error spotted [ $word, $pos ]
		_label       => '_label',       # label hosting the misspelled word
		_list        => '_list',        # listbox listing the suggestions
		_offset      => '_offset',      # offset of _text within the editor
		                                # _plugin      => '_plugin',      # reference to spellcheck plugin
		_parent      => '_parent',      # reference to spellcheck plugin
		_sizer       => '_sizer',       # window sizer
		_text        => '_text',        # text being spellchecked
		                                # _iso_name    => '_iso_name',    # our stored dictonary lanaguage
	},
};

# use Data::Printer {
	# caller_info => 1,
	# colored     => 1,
# };

use Encode;
use Padre::Logger;
use Padre::Locale                           ();
use Padre::Unload                           ();
use Padre::Plugin::SpellCheck::FBP::Checker ();

our $VERSION = '1.23';
our @ISA     = qw{
	Padre::Plugin::SpellCheck::FBP::Checker
};


#######
# Method new
#######
sub new {
	my $class   = shift;
	my $_parent = shift; # parent $self

	# Create the dialog
	my $self = $class->SUPER::new( $_parent->main );

	# for access to P-P-SpellCheck DB config
	$self->{_parent} = $_parent;

	# define where to display main dialog
	$self->CenterOnParent;

	$self->set_up;

	return $self;
}

#######
# Method set_up
#######
sub set_up {
	my $self    = shift;
	my $main    = $self->main;
	my $current = $main->current;

	# p $self->{_parent}->config_read;

	my $text_spell = $self->{_parent}->config_read->{Engine};
	my $iso_name   = $self->{_parent}->config_read->{$text_spell};

	#Thanks alias
	my $status_info = "$text_spell => " . $self->padre_locale_label($iso_name);
	$self->{status_info}->GetStaticBox->SetLabel($status_info);


	# TODO: maybe grey out the menu option if
	# no file is opened?
	unless ( $current->document ) {
		$main->message( Wx::gettext('No document opened.'), 'Padre' );
		return;
	}

	my $mime_type = $current->document->mimetype;
	require Padre::Plugin::SpellCheck::Engine;
	my $engine = Padre::Plugin::SpellCheck::Engine->new( $mime_type, $iso_name, $text_spell );

	# fetch text to check
	my $selection = $current->text;
	my $wholetext = $current->document->text_get;
	my $text      = $selection || $wholetext;
	my $offset    = $selection ? $current->editor->GetSelectionStart : 0;

	# try to find a mistake
	my ( $word, $pos ) = $engine->check($text);
	my @error = $engine->check($text);

	$self->{error} = \@error;


	# no mistake means bbb we're done
	if ( not defined $word ) {

		# $main->message( Wx::gettext('Spell check finished.'), 'Padre' );
		# $self->{replace}->Disable;
		# $self->{replace_all}->Disable;
		# $self->{ignore}->Disable;
		# $self->{ignore_all}->Disable;
		return;
	}

	$self->_engine($engine);
	$self->_offset($offset);
	$self->_text($text);

	$self->_autoreplace( {} );

	$self->_update;

	return;
}

#######
# Method _update;
# update the dialog box with current error. aa
#######
sub _update {
	my $self    = shift;
	my $main    = $self->main;
	my $current = $main->current;
	my $editor  = $current->editor;

	my $error = $self->{error};
	my ( $word, $pos ) = @$error;

	# update selection in parent window
	## my $editor = Padre::Current->editor;
	my $offset = $self->_offset;
	my $from   = $offset + $pos + $self->_engine->_utf_chars;
	my $to     = $from + length Encode::encode_utf8($word);
	$editor->goto_pos_centerize($from);
	$editor->SetSelection( $from, $to );

	# update label
	$self->labeltext->SetLabel('Not in dictionary:');
	$self->label->SetLabel($word);

	# update list
	my @suggestions = $self->_engine->get_suggestions($word);

	$self->list->DeleteAllItems;
	my $i = 0;
	foreach my $w ( reverse @suggestions ) {
		next unless defined $w;
		my $item = Wx::ListItem->new;
		$item->SetText($w);
		my $idx = $self->list->InsertItem($item);
		last if ++$i == 32; #TODO Fixme: should be a preference, why
	}

	# select first item
	my $item = $self->list->GetItem(0);
	$item->SetState(Wx::wxLIST_STATE_SELECTED);
	$self->list->SetItem($item);
	
	return;
}


#######
# dialog->_next;
#
# try to find next mistake, and update dialog to show this new error. if
# no error, display a message and exit.
#
# no params. no return value.
#######
sub _next {
	my ($self) = @_;
	my $autoreplace = $self->_autoreplace;

	# try to find next mistake
	my ( $word, $pos ) = $self->_engine->check( $self->_text );

	my @error = $self->_engine->check( $self->_text );
	$self->{error} = \@error;

	# no mistake means we're done
	if ( not defined $word ) {
		$self->list->DeleteAllItems;
		$self->labeltext->SetLabel('Spell check finished:...');
		$self->label->SetLabel('Click Close');

		# $self->replace->Disable;
		# $self->replace_all->Disable;
		# $self->{ignore}->Disable;
		# $self->{ignore_all}->Disable;
		# $self->list->DeleteAllItems;
		return;
	}

	# check if we have hit a replace all word
	if ( exists $autoreplace->{$word} ) {
		$self->_replace( $autoreplace->{$word} );
		redo; # move on to next error
	}

	# update gui with new error
	$self->_update;
	return;
}

#######
# Method _replace( $word );
#
# fix current error by replacing faulty word with $word.
#
# no param. no return value.
#######
sub _replace {
	my ( $self, $new ) = @_;
	my $main   = $self->main;
	my $editor = $main->current->editor;

	# replace word in editor
	my $error = $self->{error};
	my ( $word, $pos ) = @$error;

	my $offset = $self->_offset;

	my $from = $offset + $pos + $self->_engine->_utf_chars;
	my $to   = $from + length Encode::encode_utf8($word);
	$editor->SetSelection( $from, $to );
	$editor->ReplaceSelection($new);

	# FIXME: as soon as STC issue is resolved:
	# Include UTF8 characters from newly added word
	# to overall count of UTF8 characters
	# so we can set proper selections
	$self->_engine->_count_utf_chars($new);

	# remove the beginning of the text, up to after replaced word
	my $posold = $pos + length $word;
	my $posnew = $pos + length $new;
	my $text   = substr $self->_text, $posold;
	$self->_text($text);
	$offset += $posnew;
	$self->_offset($offset);
	
	return;
}


########
# Event Handlers
########

#######
# Event Handler _on_ignore_all_clicked;
#######
sub _on_ignore_all_clicked {
	my $self  = shift;
	my $error = $self->{error};
	my ( $word, $pos ) = @$error;
	$self->_engine->set_ignore_word($word);
	$self->_on_ignore_clicked;
	
	return;
}

#######
# Event Handler$self->_on_ignore_clicked;
#######
sub _on_ignore_clicked {
	my $self = shift;

	# remove the beginning of the text, up to after current error
	my $error = $self->{error};
	my ( $word, $pos ) = @$error;

	$pos += length $word;
	my $text = substr $self->_text, $pos;
	$self->_text($text);
	my $offset = $self->_offset + $pos;
	$self->_offset($offset);

	# FIXME: as soon as STC issue is resolved:
	# Include UTF8 characters from ignored word
	# to overall count of UTF8 characters
	# so we can set proper selections
	$self->_engine->_count_utf_chars($word);

	# try to find next error
	$self->_next;
	return;
}

#######
# Event Handler _on_replace_all_clicked;
#######
sub _on_replace_all_clicked {
	my $self  = shift;
	my $error = $self->{error};
	my ( $word, $pos ) = @$error;

	# get replacing word
	my $index = $self->list->GetNextItem( -1, Wx::wxLIST_NEXT_ALL, Wx::wxLIST_STATE_SELECTED );
	return if $index == -1;
	my $selected_word = $self->list->GetItem($index)->GetText;

	# store automatic replacement
	$self->_autoreplace->{$word} = $selected_word;

	# do the replacement
	$self->_on_replace_clicked;
	return;
}

#######
# Event Handler _on_replace_clicked;
#######
sub _on_replace_clicked {
	my $self  = shift;
	my $event = shift;

	# get replacing word
	my $index = $self->list->GetNextItem( -1, Wx::wxLIST_NEXT_ALL, Wx::wxLIST_STATE_SELECTED );
	return if $index == -1;
	my $selected_word = $self->list->GetItem($index)->GetText;

	# actually replace word in editor
	$self->_replace($selected_word);

	# try to find next error
	$self->_next;
	return;
}

#######
# Composed Method padre_local_label
# aspell to padre local label
#######
sub padre_locale_label {
	my $self             = shift;
	my $local_dictionary = shift;

	my $lc_local_dictionary = lc( $local_dictionary ? $local_dictionary : 'en_GB' );
	$lc_local_dictionary =~ s/_/-/;
	require Padre::Locale;
	my $label = Padre::Locale::label($lc_local_dictionary);

	return $label;
}

1;

__END__

# Copyright 2008-2012 The Padre development team as listed in Padre.pm.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.
