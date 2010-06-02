package Padre::Wx::Outline;

use 5.008;
use strict;
use warnings;
use Params::Util      ();
use Padre::Wx         ();
use Padre::Current    ();
use Padre::Task2Owner ();
use Padre::Logger;

our $VERSION = '0.62';
our @ISA     = qw{
	Padre::Task2Owner
	Wx::TreeCtrl
};






######################################################################
# Constructor and Accessors

sub new {
	my $class = shift;
	my $main  = shift;
	my $self  = $class->SUPER::new(
		$main->right,
		-1,
		Wx::wxDefaultPosition,
		Wx::wxDefaultSize,
		Wx::wxTR_HIDE_ROOT | Wx::wxTR_SINGLE | Wx::wxTR_HAS_BUTTONS | Wx::wxTR_LINES_AT_ROOT
	);
	$self->SetIndent(10);

	Wx::Event::EVT_COMMAND_SET_FOCUS(
		$self, $self,
		sub {
			$self->on_tree_item_set_focus( $_[1] );
		},
	);

	# Double-click a function name
	Wx::Event::EVT_TREE_ITEM_ACTIVATED(
		$self, $self,
		sub {
			$self->on_tree_item_activated( $_[1] );
		}
	);

	$self->Hide;

	$self->{cache} = {};

	return $self;
}

sub right {
	$_[0]->GetParent;
}

sub main {
	$_[0]->GetGrandParent;
}

sub gettext_label {
	Wx::gettext('Outline');
}

sub clear {
	$_[0]->DeleteAllItems;
}





################################################################
# Cache routines

sub store_in_cache {
	my ( $self, $cache_key, $content ) = @_;

	if ( defined $cache_key ) {
		$self->{cache}->{$cache_key} = $content;
	}
	return;
}

sub get_from_cache {
	my ( $self, $cache_key ) = @_;

	if ( defined $cache_key and exists $self->{cache}->{$cache_key} ) {
		return $self->{cache}->{$cache_key};
	}
	return;
}





#####################################################################
# GUI routines

sub task_response {
	my $self = shift;
	my $task = shift;
	my $data = $task->{data};
	my $lock = Padre::Current->main->lock('UPDATE');

	# If there is no structure do nothing (we are already cleared)
	return unless $data;
	return 1 unless @$data;

	# Add the hidden unused root
	my $root = $self->AddRoot(
		Wx::gettext('Outline'),
		-1,
		-1,
		Wx::TreeItemData->new('')
	);

	# Add the packge trees
	foreach my $pkg ( @$data ) {
		my $branch = $self->AppendItem(
			$root,
			$pkg->{name},
			-1, -1,
			Wx::TreeItemData->new(
				{   line => $pkg->{line},
					name => $pkg->{name},
					type => 'package',
				}
			)
		);
		foreach my $type (qw(pragmata modules attributes methods events)) {
			$self->add_subtree( $pkg, $type, $branch );
		}
		$self->Expand($branch);
	}

	# Set MIME type specific event handler
	Wx::Event::EVT_TREE_ITEM_RIGHT_CLICK(
		$self,
		$self,
		sub {
			$_[0]->on_tree_item_right_click($_[1]);
		},
	);

	# TO DO Expanding all is not acceptable: We need to keep the state
	# (i.e., keep the pragmata subtree collapsed if it was collapsed
	# by the user)
	#$self->ExpandAll;
	$self->GetBestSize;
	$self->Thaw;

	# Disable caching for the moment
	# $self->store_in_cache( $filename, [ $data, $right_click_handler ] );

	return 1;
}

sub add_subtree {
	my ( $self, $pkg, $type, $root ) = @_;

	my %type_caption = (
		pragmata => Wx::gettext('Pragmata'),
		modules  => Wx::gettext('Modules'),
		methods  => Wx::gettext('Methods'),
	);

	my $type_elem = undef;
	if ( defined( $pkg->{$type} ) && scalar( @{ $pkg->{$type} } ) > 0 ) {
		my $type_caption = ucfirst($type);
		if ( exists $type_caption{$type} ) {
			$type_caption = $type_caption{$type};
		} else {
			warn "Type not translated: $type_caption\n";
		}

		$type_elem = $self->AppendItem(
			$root,
			$type_caption,
			-1,
			-1,
			Wx::TreeItemData->new()
		);

		my @sorted_entries = ();
		if ( $type eq 'methods' ) {
			my $config = $self->main->{ide}->config;
			if ( $config->main_functions_order eq 'original' ) {

				# That should be the one we got
				@sorted_entries = @{ $pkg->{$type} };
			} elsif ( $config->main_functions_order eq 'alphabetical_private_last' ) {

				# ~ comes after \w
				my @pre = map { $_->{name} =~ s/^_/~/; $_ } @{ $pkg->{$type} };
				@pre = sort { $a->{name} cmp $b->{name} } @pre;
				@sorted_entries = map { $_->{name} =~ s/^~/_/; $_ } @pre;
			} else {

				# Alphabetical (aka 'abc')
				@sorted_entries = sort { $a->{name} cmp $b->{name} } @{ $pkg->{$type} };
			}
		} else {
			@sorted_entries = sort { $a->{name} cmp $b->{name} } @{ $pkg->{$type} };
		}

		foreach my $item (@sorted_entries) {
			$self->AppendItem(
				$type_elem,
				$item->{name},
				-1, -1,
				Wx::TreeItemData->new(
					{   line => $item->{line},
						name => $item->{name},
						type => $type,
					}
				)
			);
		}
	}
	if ( defined $type_elem ) {
		if ( $type eq 'methods' ) {
			$self->Expand($type_elem);
		} else {
			$self->Collapse($type_elem);
		}
	}

	return;
}





#####################################################################
# Timer Control

sub start {
	my $self = shift;
	@_ = (); # Feeble attempt to kill Scalars Leaked ($self is leaking)

	# TO DO: GUI on-start initialisation here

	# Set up or reinitialise the timer
	if ( Params::Util::_INSTANCE( $self->{timer}, 'Wx::Timer' ) ) {
		$self->{timer}->Stop if $self->{timer}->IsRunning;
	} else {
		$self->{timer} = Wx::Timer->new(
			$self,
			Padre::Wx::ID_TIMER_OUTLINE
		);
		Wx::Event::EVT_TIMER(
			$self,
			Padre::Wx::ID_TIMER_OUTLINE,
			sub {
				$self->on_timer( $_[1], $_[2] );
			},
		);
	}
	$self->{timer}->Start(1000);
	$self->on_timer( undef, 1 );

	return ();
}

sub stop {
	my $self = shift;

	TRACE("stopping Outline") if DEBUG;

	# Stop the timer
	if ( Params::Util::_INSTANCE( $self->{timer}, 'Wx::Timer' ) ) {
		$self->{timer}->Stop if $self->{timer}->IsRunning;
	}

	$self->clear;

	# TO DO: GUI on-stop cleanup here

	return ();
}

sub on_timer {
	my $self  = shift;
	my $event = shift;

	# Clear the event
	$event->Skip(0) if defined $event;

	# Reuse the refresh logic here
	$self->refresh;
}

sub refresh {
	my $self = shift;

	# Flush the old state
	$self->clear;
	$self->revision_change;

	# Fire the task to get the new state
	my $document = Padre::Current->document or return;
	my $task     = $document->task_outline  or return;
	$self->schedule(
		task => $task,
		text => $document->text_get,
	);
}

sub running {
	!!( $_[0]->{timer} and $_[0]->{timer}->IsRunning );
}





#####################################################################
# Event Handlers

sub on_tree_item_right_click {
	my $self   = shift;
	my $event  = shift;
	my $show   = 0;
	my $menu   = Wx::Menu->new;
	my $pldata = $self->GetPlData( $event->GetItem );

	if ( defined($pldata) && defined( $pldata->{line} ) && $pldata->{line} > 0 ) {
		my $goto = $menu->Append( -1, Wx::gettext('&Go to Element') );
		Wx::Event::EVT_MENU(
			$self, $goto,
			sub {
				$self->on_tree_item_set_focus($event);
			},
		);
		$show++;
	}

	if (   defined($pldata)
		&& defined( $pldata->{type} )
		&& ( $pldata->{type} eq 'modules' || $pldata->{type} eq 'pragmata' ) )
	{
		my $pod = $menu->Append( -1, Wx::gettext('Open &Documentation') );
		Wx::Event::EVT_MENU(
			$self,
			$pod,
			sub {

				# TO DO Fix this wasting of objects (cf. Padre::Wx::Menu::Help)
				require Padre::Wx::DocBrowser;
				my $help = Padre::Wx::DocBrowser->new;
				$help->help( $pldata->{name} );
				$help->SetFocus;
				$help->Show(1);
				return;
			},
		);
		$show++;
	}

	if ( $show > 0 ) {
		my $x = $event->GetPoint->x;
		my $y = $event->GetPoint->y;
		$self->PopupMenu( $menu, $x, $y );
	}

	return;
}

sub on_tree_item_set_focus {
	my ( $self, $event ) = @_;
	my $main      = Padre::Current->main($self);
	my $page      = $main->current->editor;
	my $selection = $self->GetSelection();
	if ( $selection and $selection->IsOk ) {
		my $item = $self->GetPlData($selection);
		if ( defined $item ) {
			$self->select_line_in_editor( $item->{line} );
		}
	}
	return;
}

sub on_tree_item_activated {
	on_tree_item_set_focus(@_);
	return;
}

sub select_line_in_editor {
	my ( $self, $line_number ) = @_;
	my $main = Padre::Current->main($self);
	my $page = $main->current->editor;
	if (   defined $line_number
		&& ( $line_number =~ /^\d+$/o )
		&& ( defined $page )
		&& ( $line_number <= $page->GetLineCount ) )
	{
		$line_number--;
		$page->EnsureVisible($line_number);
		$page->goto_pos_centerize( $page->GetLineIndentPosition($line_number) );
		$page->SetFocus;
	}
	return;
}

1;

# Copyright 2008-2010 The Padre development team as listed in Padre.pm.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.
