package Padre::Plugin::Perl6::UpdateDialog;

use 5.010;
use strict;
use warnings;

# package exports and version
our $VERSION = '0.60';
our @ISA     = 'Wx::Dialog';

# module imports
use Padre::Wx       ();
use Padre::Wx::Icon ();

# accessors
use Class::XSAccessor accessors => {
	_hbox        => '_hbox',        # horizontal box sizer
	_list        => '_list',        # matches list
	_help_viewer => '_help_viewer', # HTML Help Viewer
	_main        => '_main',        # Padre's main window
};

# -- constructor
sub new {
	my ( $class, $main, %opt ) = @_;

	# create object
	my $self = $class->SUPER::new(
		$main,
		-1,
		Wx::gettext('Six Updater Tool'),
		Wx::wxDefaultPosition,
		Wx::wxDefaultSize,
		Wx::wxDEFAULT_FRAME_STYLE | Wx::wxTAB_TRAVERSAL,
	);

	$self->_main($main);

	# Dialog's icon as is the same as Padre
	$self->SetIcon(Padre::Wx::Icon::PADRE);

	# create dialog
	$self->_create;

	$self->prepare;

	# fit and center the dialog
	$self->Fit;
	$self->CentreOnParent;

	return $self;
}


#
# Fetches the current selection's help HTML
#
sub _display_help_in_viewer {
	my $self = shift;

	my ( $html, $location );
	my $selection = $self->_list->GetSelection();
	if ( $selection != -1 ) {
		my $topic = $self->_list->GetClientData($selection);
	}

	if ( not $html ) {
		$html = '<b>' . Wx::gettext('Not found') . '</b>';
	}

	$self->_help_viewer->SetPage($html);

	return;
}

# -- private methods

#
# create the dialog itself.
#
sub _create {
	my $self = shift;

	# create sizer that will host all controls
	$self->_hbox( Wx::BoxSizer->new(Wx::wxHORIZONTAL) );

	# create the controls
	$self->_create_controls;

	# wrap everything in a box to add some padding
	$self->SetMinSize( [ 640, 480 ] );
	$self->SetSizer( $self->_hbox );

	return;
}

#
# create controls in the dialog
#
sub _create_controls {
	my $self = shift;

	# matches result list
	my $matches_label = Wx::StaticText->new(
		$self, -1,
		Wx::gettext('Please select a Six release to install:')
	);
	$self->_list(
		Wx::ListBox->new(
			$self,
			-1,
			Wx::wxDefaultPosition,
			[ 180, -1 ],
			[],
			Wx::wxLB_SINGLE
		)
	);

	# HTML Help Viewer
	require Padre::Wx::HtmlWindow;
	$self->_help_viewer(
		Padre::Wx::HtmlWindow->new(
			$self,
			-1,
			Wx::wxDefaultPosition,
			Wx::wxDefaultSize,
			Wx::wxBORDER_STATIC
		)
	);
	$self->_help_viewer->SetPage('');

	my $close_button = Wx::Button->new( $self, Wx::wxID_CANCEL, Wx::gettext('&Close') );

	my $vbox = Wx::BoxSizer->new(Wx::wxVERTICAL);

	$vbox->Add( $matches_label,  0, Wx::wxALL | Wx::wxEXPAND,     2 );
	$vbox->Add( $self->_list,  1, Wx::wxALL | Wx::wxEXPAND,     2 );
	$vbox->Add( $close_button, 0, Wx::wxALL | Wx::wxALIGN_LEFT, 0 );
	$self->_hbox->Add( $vbox, 0, Wx::wxALL | Wx::wxEXPAND, 2 );
	$self->_hbox->Add(
		$self->_help_viewer,                                                        1,
		Wx::wxALL | Wx::wxALIGN_TOP | Wx::wxALIGN_CENTER_HORIZONTAL | Wx::wxEXPAND, 1
	);

	$self->_setup_events();

	return;
}

#
# Adds various events
#
sub _setup_events {
	my $self = shift;

	Wx::Event::EVT_HTML_LINK_CLICKED(
		$self,
		$self->_help_viewer,
		\&on_link_clicked,
	);


	Wx::Event::EVT_LISTBOX(
		$self,
		$self->_list,
		sub {
			$self->_display_help_in_viewer;
		}
	);

	return;
}

#
# Prepares the UI
#
sub prepare {
	my $self = shift;

	# Show to the user a list of hardcoded-for-now releases
	#XXX- remove hardcoding in the future by using an index.yaml file
	#     at the server.
	my $releases = {
		'01' => {
			name     => 'Six Seattle #21 (September 2009)',
			url      => 'http://feather.perl6.nl/~azawawi/six/six-seattle.zip',
			desc_url => 'http://github.com/rakudo/rakudo/raw/master/docs/announce/2009-09',
		},
		'02' => {
			name     => 'Six PDX #20 (August 2009)',
			url      => 'http://feather.perl6.nl/~azawawi/six/six-pdx.zip',
			desc_url => 'http://github.com/rakudo/rakudo/raw/master/docs/announce/2009-08',
		},
		'03' => {
			name     => 'Six Mini (Only for testing. Please ignore)',
			url      => 'http://feather.perl6.nl/~azawawi/six/six-test.zip',
			desc_url => 'http://github.com/rakudo/rakudo/raw/master/docs/announce/2009-09',
		},
	};
	my @choices     = map { $releases->{$_}->{name} } sort keys %$releases;
	my $client_data = [ map { $releases->{$_} } sort keys %$releases ];


#	if ( $dlg->ShowModal == Wx::wxID_OK ) {
#		my $selection = $dlg->GetSelectionClientData;
#
#		#Start the update task in the background
#		require Padre::Plugin::Perl6::UpdateTask;
#		my $task = Padre::Plugin::Perl6::UpdateTask->new( release => $selection );
#		$task->schedule;
#	} else {
#		$self->main->message( Wx::gettext('Operation cancelled') );
#	}

	#	#Populate the list box now
	$self->_list->Clear();
	my $pos = 0;
	foreach my $target ( @choices ) {
		$self->_list->Insert( $target, $pos, $target );
		$pos++;
	}
	if ( $pos > 0 ) {
		$self->_list->Select(0);
	}
	$self->_display_help_in_viewer;
	
	return;
}

#
# Called when the user clicks a link in the
# help viewer HTML window
#
sub on_link_clicked {
	my $self = shift;
	require URI;
	my $uri = URI->new( $_[0]->GetLinkInfo->GetHref );

	# otherwise, let the default browser handle it...
	Padre::Wx::launch_browser($uri);
}

1;

__END__

=head1 AUTHOR

Ahmad M. Zawawi C<< <ahmad.zawawi at gmail.com> >>

Gabor Szabo L<http://szabgab.com/>

=head1 COPYRIGHT AND LICENSE

Copyright 2008-2009 Padre Developers as in Perl6.pm

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl 5 itself.
