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
		_sizer       => '_sizer',       # window sizer
		_text        => '_text',        # text being spellchecked
		_iso_name    => '_iso_name',    # our stored dictonary lanaguage
	},
};

# use Padre::Current;
# use Padre::Wx   ();
# use Padre::Util ('_T');
use Encode;
use Padre::Logger;
use Padre::Unload                          ();
use Padre::Plugin::SpellCheck::FBP::Checker ();

our $VERSION = '1.22';
our @ISA     = qw{
	Padre::Plugin::SpellCheck::FBP::Checker
};

# -- constructor

#######
# Method new
#######
sub new {
	my $class = shift;
	# my $main  = shift; # Padre $main window integration
	# my $lang_iso = shift;

	my $_parent = shift; # parent $self

	# Create the dialog
	my $self = $class->SUPER::new($_parent->main);
	my $lang_iso = $_parent->config_read->{Aspell};
	$self->_iso_name($lang_iso);

	#TODO there must be a better way
	# $self->{_plugin} = $_plugin;

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

	# my $iso     = $self->iso;

	# TODO: maybe grey out the menu option if
	# no file is opened?
	unless ( $current->document ) {
		$main->message( Wx::gettext('No document opened.'), 'Padre' );
		return;
	}

	my $mime_type = $current->document->mimetype;
	require Padre::Plugin::SpellCheck::Engine;
	my $engine = Padre::Plugin::SpellCheck::Engine->new( $mime_type, $self->_iso_name );

	# fetch text to check
	my $selection = $current->text;
	my $wholetext = $current->document->text_get;
	my $text      = $selection || $wholetext;
	# p $text;
	my $offset = $selection ? $current->editor->GetSelectionStart : 0;

	# try to find a mistake
	my ( $word, $pos ) = $engine->check($text);

	# p $word;
	# p $pos;
	my @error = $engine->check($text);

	# p @error;
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

	# $self->_error( $word, $pos );
	$self->_engine($engine);
	$self->_offset($offset);
	$self->_text($text);

	# # $self->_plugin( $_plugin );
	$self->_autoreplace( {} );

	# create the controls
	$self->_create_labels;


	$self->_update;

	return;
}

#
# $dialog->_create_labels;
#
# create the top labels.
#
# no params. no return values.
#
sub _create_labels {
	my $self = shift;

	#TODO alias how do we change the contents of the top bar, known as 'title'
	# $self->title->SetLabel( 'FUN' );
	#
	# Status Info.
	#	labeltext	_label
	#
	# $self->{status_info}->SetLabel('iso');
	$self->labeltext->SetLabel('ready willing &');
	$self->label->SetLabel('able');
	return;
}

#
# self->_update;
#
# update the dialog box with current error. aa
#
sub _update {
	my $self    = shift;
	my $main    = $self->main;
	my $current = $main->current;
	my $editor  = $current->editor;

	# my $error = $self->_error;
	# my ( $word, $pos ) = @$error;

	# p $self->{error};

	my $error = $self->{error};

	# p $error;
	my ( $word, $pos ) = @$error;

	# p @error;
	# my ( $word, $pos ) = @{$self->{error}};
	# p $word;
	# p $pos;

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
	my @suggestions = $self->_engine->suggestions($word);

	# my $list        = $self->_list;
	# $list->DeleteAllItems;
	$self->list->DeleteAllItems;
	my $i = 0;
	foreach my $w ( reverse @suggestions ) {
		next unless defined $w;
		my $item = Wx::ListItem->new;
		$item->SetText($w);
		my $idx = $self->list->InsertItem($item);
		last if ++$i == 32; #TODO Fixme: should be a preference
	}

	# select first item
	my $item = $self->list->GetItem(0);
	$item->SetState(Wx::wxLIST_STATE_SELECTED);
	$self->list->SetItem($item);
}



# -- private methods





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
		my ( $word, $pos ) = $self->_engine->check( $self->_text );

		# $self->_error( [ $word, $pos ] );

		my @error = $self->_engine->check( $self->_text );
		$self->{error} = \@error;

		# my $error = $self->{error};
		# my ( $word, $pos ) = @error;

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
	my ( $self, $new ) = @_;
	my $main   = $self->main;
	my $editor = $main->current->editor;

	# my $editor = Padre::Current->editor;

	# replace word in editor
	my $error = $self->{error};
	my ( $word, $pos ) = @$error;

	# my $error  = $self->_error;
	my $offset = $self->_offset;

	# my ( $word, $pos ) = @$error;
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
}





# -- public methods





########
# Event Handlers
########

#
# $self->_on_butclose_clicked;
#
# handler called when the close button has been clicked.
#
# sub _on_butclose_clicked {
# my $self = shift;
# $self->Destroy;
# }

#
# $self->_on_butignore_all_clicked;
#
# handler called when the ignore all button has been clicked.
#
sub _on_ignore_all_clicked {
	my $self  = shift;
	my $error = $self->{error};
	my ( $word, $pos ) = @$error;
	$self->_engine->ignore($word);
	$self->_on_ignore_clicked;
}

#
# $self->_on_butignore_clicked;
#
# handler called when the ignore button has been clicked.
#
sub _on_ignore_clicked {
	my $self = shift;

	# remove the beginning of the text, up to after current error
	my $error = $self->{error};
	my ( $word, $pos ) = @$error;

	# my $error = $self->_error;
	# my ( $word, $pos ) = @$error;
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
}

#
# $self->_on_butreplace_all_clicked;
#
# handler called when the replace all button has been clicked.
#
sub _on_replace_all_clicked {
	my $self  = shift;
	my $error = $self->{error};
	my ( $word, $pos ) = @$error;

	# get replacing word
	# my $list = $self->_list;
	my $index = $self->list->GetNextItem( -1, Wx::wxLIST_NEXT_ALL, Wx::wxLIST_STATE_SELECTED );
	return if $index == -1;
	my $selected_word = $self->list->GetItem($index)->GetText;

	# store automatic replacement
	# my $old = $self->_error->[0];
	$self->_autoreplace->{$word} = $selected_word;

	# do the replacement
	$self->_on_replace_clicked;
}

#
# $self->_on_butreplace_clicked;
#
# handler called when the replace button has been clicked.
#
sub _on_replace_clicked {
	my $self  = shift;
	my $event = shift;

	# my $list = $self->_list;

	# get replacing word
	my $index = $self->list->GetNextItem( -1, Wx::wxLIST_NEXT_ALL, Wx::wxLIST_STATE_SELECTED );

	# p $index;
	return if $index == -1;
	my $selected_word = $self->list->GetItem($index)->GetText;
	# p $selected_word;

	# actually replace word in editor
	$self->_replace($selected_word);

	# try to find next error
	$self->_next;
}






1;

__END__

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

=cut
