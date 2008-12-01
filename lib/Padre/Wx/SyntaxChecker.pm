package Padre::Wx::SyntaxChecker;
use strict;
use warnings;

our $VERSION = '0.19';

require Padre;
use Padre::Wx;

use Class::XSAccessor
	getters => {
		mw => 'mw',
		syntaxbar => 'syntaxbar',
	};

sub new {
	my $class = shift;
	my $mw = shift;

	my $self = bless {
		@_,
		mw => $mw,
	} => $class;

	$self->create_syntaxbar($mw);
	return $self;
}

sub DESTROY {
	my $self = shift;
	delete $self->{mw};
}

sub create_syntaxbar {
	my $self = shift;
	my $mw = $self->mw;

	$self->{syntaxbar} = Wx::ListView->new(
		$mw,
		Wx::wxID_ANY,
		Wx::wxDefaultPosition,
		Wx::wxDefaultSize,
		Wx::wxLC_REPORT | Wx::wxLC_SINGLE_SEL
	);
	$self->{syntaxbar}->InsertColumn( 0, Wx::gettext('Line') );
	$self->{syntaxbar}->InsertColumn( 1, Wx::gettext('Type') );
	$self->{syntaxbar}->InsertColumn( 2, Wx::gettext('Description') );
	$mw->manager->AddPane($self->{syntaxbar},
		Wx::AuiPaneInfo->new->Name( "syntaxbar" )
			->CenterPane->Resizable(1)->PaneBorder(1)->Movable(1)
			->CaptionVisible(1)->CloseButton(1)->DestroyOnClose(0)
			->MaximizeButton(1)->Floatable(1)->Dockable(1)
			->Caption( Wx::gettext("Syntax") )->Position(3)->Bottom->Layer(2)
	);
	Wx::Event::EVT_LIST_ITEM_ACTIVATED(
		$mw,
		$self->{syntaxbar},
		\&on_syntax_check_msg_selected,
	);
	if ( $mw->{menu}->{view_show_syntaxcheck}->IsChecked ) {
		$mw->manager->GetPane('syntaxbar')->Show();
	}
	else {
		$mw->manager->GetPane('syntaxbar')->Hide();
	}

	return;
}


sub enable {
	my $self = shift;
	my $on   = shift;

	my $mw   = $self->mw;

	if ($on) {
		if (   defined( $self->{synCheckTimer} )
			&& ref $self->{synCheckTimer} eq 'Wx::Timer'
		) {
			Wx::Event::EVT_IDLE( $mw, \&syntax_check_idle_timer );
			on_syntax_check_timer( $mw, undef, 1 );
		}
		else {
			$self->{synCheckTimer} = Wx::Timer->new($mw, Padre::Wx::id_SYNCHK_TIMER);
			Wx::Event::EVT_TIMER( $mw, Padre::Wx::id_SYNCHK_TIMER, \&on_syntax_check_timer );
			Wx::Event::EVT_IDLE( $mw, \&syntax_check_idle_timer );
		}
		$mw->show_syntaxbar(1);
	}
	else {
		if (   defined($self->{synCheckTimer})
			&& ref $self->{synCheckTimer} eq 'Wx::Timer'
		) {
			$self->{synCheckTimer}->Stop;
			Wx::Event::EVT_IDLE( $mw, sub { return } );
		}
		my $id   = $mw->{notebook}->GetSelection;
		my $page = $mw->{notebook}->GetPage($id);
		if ( defined($page) ) {
			$page->MarkerDeleteAll(Padre::Wx::MarkError);
			$page->MarkerDeleteAll(Padre::Wx::MarkWarn);
		}
		$self->{syntaxbar}->DeleteAllItems;
		$mw->show_syntaxbar(0);
	}

	# Setup a margin to hold fold markers
	foreach my $editor ($mw->pages) {
		if ($on) {
			$editor->SetMarginType(1, Wx::wxSTC_MARGIN_SYMBOL); # margin number 1 for symbols
			$editor->SetMarginWidth(1, 16);                     # set margin 1 16 px wide
		} else {
			$editor->SetMarginWidth(1, 0);
		}
	}

	return;
}



sub syntax_check_idle_timer {
	my ( $mw, $event ) = @_;
	my $self = $mw->syntax_checker;

	$self->{synCheckTimer}->Stop if $self->{synCheckTimer}->IsRunning;
	$self->{synCheckTimer}->Start(50, 1);

	$event->Skip(0);
	return;
}



sub on_syntax_check_msg_selected {
	my ($mw, $event) = @_;

	my $id   = $mw->{notebook}->GetSelection;
	my $page = $mw->{notebook}->GetPage($id);

	my $line_number = $event->GetItem->GetText;
	return if  not defined($line_number)
			or $line_number !~ /^\d+$/o
			or $page->GetLineCount < $line_number;

	$line_number--;
	$page->EnsureVisible($line_number);
	$page->GotoPos( $page->GetLineIndentPosition($line_number) );
	$page->SetFocus;

	return;
}


sub on_syntax_check_timer {
	my ( $win, $event, $force ) = @_;
	my $self = $win->syntax_checker;
	my $syntaxbar = $self->syntaxbar;

	my $id = $win->{notebook}->GetSelection;
	if ( defined $id ) {
		my $page = $win->{notebook}->GetPage($id);

		unless (   defined( $page->{Document} )
				&& $page->{Document}->can_check_syntax
		) {
			if ( ref $page eq 'Padre::Wx::Editor' ) {
				$page->MarkerDeleteAll(Padre::Wx::MarkError);
				$page->MarkerDeleteAll(Padre::Wx::MarkWarn);
			}
			$syntaxbar->DeleteAllItems;
			return;
		}

		my $messages = $page->{Document}->check_syntax( $force, $id );
		return unless defined $messages; # no immediate results
		$self->update_gui_with_syntax_check_results( $messages, $id );

	}


	if ( defined($event) ) {
		$event->Skip(0);
	}

	return;
}

# separated because it may be called from an
# event handler of an asynchroneous syntax checker task
sub update_gui_with_syntax_check_results {
	my $self = shift;
	my $messages = shift;
	my $id = shift; # the notebook page id
	my $win = $self->mw;
	my $syntaxbar = $self->syntaxbar;
	my $page = $win->{notebook}->GetPage($id);

	if ( scalar(@{$messages}) > 0 ) {
		$page->MarkerDeleteAll(Padre::Wx::MarkError);
		$page->MarkerDeleteAll(Padre::Wx::MarkWarn);

		my $red = Wx::Colour->new("red");
		my $orange = Wx::Colour->new("orange");
		$page->MarkerDefine(Padre::Wx::MarkError, Wx::wxSTC_MARK_SMALLRECT, $red, $red);
		$page->MarkerDefine(Padre::Wx::MarkWarn,  Wx::wxSTC_MARK_SMALLRECT, $orange, $orange);

		my $i = 0;
		$syntaxbar->DeleteAllItems;
		delete $page->{synchk_calltips};
		my $last_hint = '';
		foreach my $hint ( sort { $a->{line} <=> $b->{line} } @{$messages} ) {
			my $l = $hint->{line} - 1;
			if ( $hint->{severity} eq 'W' ) {
				$page->MarkerAdd( $l, 2);
			}
			else {
				$page->MarkerAdd( $l, 1);
			}
			my $idx = $syntaxbar->InsertStringItem( $i++, $l + 1 );
			$syntaxbar->SetItem( $idx, 1, $hint->{severity} );
			$syntaxbar->SetItem( $idx, 2, $hint->{msg} );

			if ( exists $page->{synchk_calltips}->{$l} ) {
				$page->{synchk_calltips}->{$l} .= "\n--\n" . $hint->{msg};
			}
			else {
				$page->{synchk_calltips}->{$l} = $hint->{msg};
			}
			$last_hint = $hint;
		}

		my $width0_default = $page->TextWidth( Wx::wxSTC_STYLE_DEFAULT, Wx::gettext("Line") . ' ' );
		my $width0 = $page->TextWidth( Wx::wxSTC_STYLE_DEFAULT, $last_hint->{line} x 2 );
		my $width1 = $page->TextWidth( Wx::wxSTC_STYLE_DEFAULT, Wx::gettext("Type") x 2 );
		my $width2 = $syntaxbar->GetSize->GetWidth - $width0 - $width1 - $syntaxbar->GetCharWidth * 2;
		$syntaxbar->SetColumnWidth( 0, ( $width0_default > $width0 ? $width0_default : $width0 ) );
		$syntaxbar->SetColumnWidth( 1, $width1 );
		$syntaxbar->SetColumnWidth( 2, $width2 );
	}
	else {
		$page->MarkerDeleteAll(Padre::Wx::MarkError);
		$page->MarkerDeleteAll(Padre::Wx::MarkWarn);
		$syntaxbar->DeleteAllItems;
	}
}


1;

# Copyright 2008 Gabor Szabo.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.
