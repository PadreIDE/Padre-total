package Padre::Plugin::Ecliptic::QuickFixDialog;

use warnings;
use strict;

# package exports and version
our $VERSION   = '0.16';
our @EXPORT_OK = ();

# module imports
use Padre::Wx ();

# is a subclass of Wx::Dialog
use base 'Wx::Dialog';

# accessors
use Class::XSAccessor accessors => {
	_plugin    => '_plugin',    # Plugin object
	_sizer     => '_sizer',     # window sizer
	_list      => '_list',      # key bindings list
	_listeners => '_listeners', # hash of quick fix listener
};

# -- constructor
sub new {
	my ( $class, $plugin ) = @_;

	my $main   = $plugin->main;
	my $editor = $plugin->current->editor;

	if ( not $editor ) {
		Wx::MessageBox(
			Wx::gettext("No filename"), Wx::gettext('Error'),
			Wx::wxOK,                   $main,
		);
		return;
	}

	my $pt = $editor->ClientToScreen( $editor->PointFromPosition( $editor->GetCurrentPos ) );

	# create a simple dialog with no border
	my $self = $class->SUPER::new(
		$main,
		-1,
		Wx::gettext('Quick Fix'),
		[ $pt->x, $pt->y + $editor->TextHeight(0) ],
		Wx::wxDefaultSize,
		Wx::wxBORDER_SIMPLE,
	);

	$self->_plugin($plugin);

	# create dialog
	$self->_create;

	# Dialog's icon as is the same as plugin's
	$self->SetIcon( $plugin->logo_icon );

	return $self;
}


# -- private methods

#
# create the dialog itself.
#
sub _create {
	my $self = shift;

	# create sizer that will host all controls
	my $sizer = Wx::BoxSizer->new(Wx::wxVERTICAL);
	$self->_sizer($sizer);

	# create the controls
	$self->_create_controls;

	# wrap everything in a vbox to add some padding
	$self->SetSizerAndFit($sizer);
	$sizer->SetSizeHints($self);

}

#
# create controls in the dialog
#
sub _create_controls {
	my $self = shift;

	$self->_create_list();

	$self->_sizer->Add( $self->_list, 0, Wx::wxALL | Wx::wxEXPAND );

	$self->_setup_events;

	return;
}

#
# Adds various events
#
sub _setup_events {
	my $self = shift;

	Wx::Event::EVT_KILL_FOCUS(
		$self->_list,
		sub {

			#list box lost focus, we should kill the dialog
			$self->Destroy;
		}
	);

	Wx::Event::EVT_CHAR(
		$self->_list,
		sub {
			my $this  = shift;
			my $event = shift;

			if ( $event->GetKeyCode == Wx::WXK_ESCAPE ) {

				# user pressed escape, let us close it...
				$self->Destroy;
			}

			$event->Skip(1);
		}
	);


	Wx::Event::EVT_LIST_ITEM_ACTIVATED(
		$self,
		$self->_list,
		sub {

			my $selection = $self->_list->GetFirstSelected;
			if ( $selection != -1 ) {
				my $listener = $self->_listeners->{$selection};
				if ($listener) {
					&{$listener}();
					$self->Destroy;
				}
			}
			return;
		}
	);

}

#
# Update matches list box from matched files list
#
sub _create_list {
	my $self = shift;

	my $main             = $self->_plugin->main;
	my $current          = $self->_plugin->current;
	my $editor           = $current->editor;
	my $list_width       = 280;
	my $editor_font      = $self->GetFont;
	my $editor_font_size = $editor->TextHeight(0) - 10;
	if ( $editor_font_size < 10 ) {
		$editor_font_size = 10;
	}
	$editor_font->SetPointSize($editor_font_size);
	$self->SetFont($editor_font);
	$self->_list(
		Wx::ListView->new(
			$self,
			-1,
			Wx::wxDefaultPosition,
			[ $list_width, 100 ],
			Wx::wxLC_REPORT | Wx::wxLC_NO_HEADER | Wx::wxLC_SINGLE_SEL | Wx::wxBORDER_NONE
		)
	);

	$self->_list->InsertColumn( 0, '' );
	$self->_list->SetColumnWidth( 0, $list_width - 5 );

	#try to  call event_on_quick_fix on the current document
	my $item_count = 0;
	my %listeners  = ();
	my $doc        = $current->document;
	if ( defined $doc && $doc->can('event_on_quick_fix') ) {

		# add list items from callbacks
		my @items = $doc->event_on_quick_fix($editor);
		foreach my $item (@items) {

			# add the list item
			$self->_list->InsertStringItem( $item_count, $item->{text} );

			# and register its action
			$listeners{$item_count} = $item->{listener};

			#next item...
			$item_count++;
		}
	}
	$self->_listeners( \%listeners );

	if ($item_count) {
		$self->_list->Select( 0, 1 );
	} else {

		# display No suggestions...
		$self->_list->InsertStringItem( $item_count, Wx::gettext("No suggestions") );
		$self->_list->Select( 0, 1 );
		$listeners{0} = sub {

			# do nothing to exit the dialog when "No suggestion" is selected...
		};
	}

	# focus on the list box
	$self->_list->SetFocus;

	return;
}


1;

__END__

=head1 AUTHOR

Ahmad M. Zawawi C<< <ahmad.zawawi at gmail.com> >>

=head1 COPYRIGHT AND LICENSE

Copyright 2009 C<< <ahmad.zawawi at gmail.com> >>

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl 5 itself.