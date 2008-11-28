package Padre::Wx::Dialog::Search;

# Incremental search

use 5.008;
use strict;
use warnings;
use Padre::Wx;

our $VERSION = '0.19';





######################################################################
# Constructor

sub new {
	my $class = shift;
	my $self  = bless {
		restart  => 1,
		backward => 0,
	}, $class;
	return $self;
}





######################################################################
# Main Methods

#
# search($direction);
#
# initiate/continue searching in $direction.
#
sub search {
	my $self      = shift;
	my $direction = shift;
	$self->{backward} = $direction eq 'previous';
	unless ( $self->{panel} ) {
		$self->{panel} = $self->_create_panel;
	}
	if ( $self->{panel}->IsShown ) {
		$self->_find;
	} else {
		$self->_show_panel;
	}
}

# -- Private methods

sub _find {
	my $self  = shift;
	my $main  = Padre->ide->wx->main_window;
	my $page  = Padre::Documents->current->editor;
	my $last  = $page->GetLength;
	my $text  = $page->GetTextRange(0, $last);

	# build regex depending on what we search for
	my $what;
	if ( $self->{regex}->GetValue ) {
		# regex search, let's validate regex
		$what = $self->{entry}->GetValue;
		eval { qr/$what/ };
		if ( $@ ) {
			# regex is invalid
			$self->{entry}->SetBackgroundColour(Wx::wxRED);
			return;
			
		} else {
			# regex is valid
			$self->{entry}->SetBackgroundColour(Wx::wxWHITE);
		}
		
	} else {
		# plain text search
		$what = quotemeta $self->{entry}->GetValue;
	}

	my $regex = $self->{case}->GetValue ? qr/$what/im : qr/$what/m;

	my ($from, $to) = $self->{restart}
		? (0, $last)
		: $page->GetSelection;
	$self->{restart} = 0;

	# search and highlight
	my ($start, $end, @matches) =
		Padre::Util::get_matches($text, $regex, $from, $to, $self->{backward});
	if ( defined $start ) {
		$page->SetSelection($start, $end);
		$self->{entry}->SetBackgroundColour(Wx::wxWHITE);
	} else {
		$self->{entry}->SetBackgroundColour(Wx::wxRED);
	}
	return;
}

# -- GUI related subs

#
# _create_panel();
#
# create find panel in aui manager.
#
sub _create_panel {
	my $self = shift;
	my $main = Padre->ide->wx->main_window;

	# The panel and the boxsizer to place controls
	$self->{panel} = Wx::Panel->new($main, -1);
	$self->{hbox}  = Wx::BoxSizer->new(Wx::wxHORIZONTAL);
	$self->{panel}->SetSizerAndFit($self->{hbox});

	# Close button
	$self->{close} = Wx::BitmapButton->new(
		$self->{panel}, -1,
		Padre::Wx::tango( 'emblems', 'emblem-unreadable.png' ),
		Wx::Point->new(-1,-1),
		Wx::Size->new(-1,-1),
		Wx::wxNO_BORDER,
	);
	Wx::Event::EVT_BUTTON($main, $self->{close}, sub { $self->_hide_panel } );

	# Search area
	$self->{label} = Wx::StaticText->new($self->{panel}, -1, Wx::gettext('Find:'));
	$self->{entry} = Wx::TextCtrl->new($self->{panel}, -1, '');
	$self->{entry}->SetMinSize(
		Wx::Size->new( 25 * $self->{entry}->GetCharWidth, -1 )
	);
	Wx::Event::EVT_CHAR(       $self->{entry}, sub { $self->_on_key_pressed($_[1])   } );
	Wx::Event::EVT_TEXT($main, $self->{entry}, sub { $self->_on_entry_changed($_[1]) } );

	# Previous button
	$self->{previous} = Wx::BitmapButton->new(
		$self->{panel}, -1,
		Padre::Wx::tango( 'actions', 'go-previous.png' ),
		Wx::Point->new(-1,-1),
		Wx::Size->new(-1,-1),
		Wx::wxNO_BORDER
	);
	Wx::Event::EVT_BUTTON($main, $self->{previous}, sub { $self->search('previous') } );

	# Previous button
	$self->{next} = Wx::BitmapButton->new(
		$self->{panel}, -1,
		Padre::Wx::tango( 'actions', 'go-next.png' ),
		Wx::Point->new(-1,-1),
		Wx::Size->new(-1,-1),
		Wx::wxNO_BORDER,
	);
	Wx::Event::EVT_BUTTON($main, $self->{next}, sub { $self->search('next') } );

	# Case sensitivity
	$self->{case} = Wx::CheckBox->new($self->{panel}, -1, Wx::gettext('Case insensitive'));
	Wx::Event::EVT_CHECKBOX($main, $self->{case}, sub { $self->_on_case_checked } );

	# Regex search
	$self->{regex} = Wx::CheckBox->new($self->{panel}, -1, Wx::gettext('Use regex'));
	Wx::Event::EVT_CHECKBOX($main, $self->{regex}, sub { $self->_on_regex_checked } );

	# Place all controls
	foreach my $element ( qw{ close label entry previous next case regex } ) {
		$self->{hbox}->Add(10,0);
		$self->{hbox}->Add($self->{$element}, 0, Wx::wxALIGN_CENTER_VERTICAL|Wx::wxALIGN_LEFT, 0);
	}

	# Make sure the panel is high enough
	$self->{panel}->Fit;

	# manage the pane in aui
	$main->manager->AddPane( $self->{panel},
		Wx::AuiPaneInfo->new->Name( 'find' )
		->Bottom
		->CaptionVisible(0)
		->Layer(1)
		->Fixed
		->Show(0)
	);

	return 1;
}

sub hide {
	$_[0]->{panel}->Hide;
	Padre->ide->wx->main_window->manager->Update;
	return 1;
}

sub show {
	my $self = shift;

	# Show the panel
	$self->{panel}->Show;
	Padre->ide->wx->main_window->manager->Update;

	# Update checkboxes with config values
	# since they might have been updated by find dialog
	my $config = Padre->ide->config;
	$self->{case}->SetValue( $config->{search}->{case_insensitive} );
	$self->{regex}->SetValue( $config->{search}->{use_regex} );

	# You probably want to use the Find
	$self->{entry}->SetFocus;

	return 1;
}

# -- Event handlers

#
# _on_case_checked()
#
# called when the "case insensitive" checkbox has changed value. in that
# case, we'll restart searching from the start of the document.
#
sub _on_case_checked {
	my $self = shift;
	Padre->ide->config->{search}->{case_insensitive} = $self->{case}->GetValue;
	$self->{restart} = 1;
	$self->_find;
	return;
}

#
# _on_entry_changed()
#
# called when the entry content has changed (keyboard or other mean). in that
# case, we'll start searching from the start of the document.
#
sub _on_entry_changed {
	$_[0]->{restart} = 1;
	$_[0]->_find;
	return;
}


#
# _on_key_pressed()
#
# called when a key is pressed in the entry. used to trap escape so we abort
# search, otherwise dispatch event up-stack.
#
sub _on_key_pressed {
	my $self  = shift;
	my $event = shift;
	my $mod  = $event->GetModifiers || 0;
	my $code = $event->GetKeyCode;

	# remove the bit ( Wx::wxMOD_META) set by Num Lock being pressed on Linux
	$mod = $mod & ( Wx::wxMOD_ALT + Wx::wxMOD_CMD + Wx::wxMOD_SHIFT );

	if ( $code == Wx::WXK_ESCAPE ) {
		$self->_hide_panel;
		return;
	}

	$event->Skip(1);
}

#
# _on_regex_checked()
#
# called when the "use regex" checkbox has changed value. in that case,
# we'll restart searching from the start of the document.
#
sub _on_regex_checked {
	my $self = shift;
	Padre->ide->config->{search}->{use_regex} = $self->{regex}->GetValue;
	$self->{restart} = 1;
	$self->_find;
	return;
}

1;

# Copyright 2008 Gabor Szabo.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.
