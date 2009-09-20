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
	_hbox            => '_hbox',            # horizontal box sizer
	_list            => '_list',            # a list
	_progress        => '_progress',        # a progress bar
	_plugin          => '_plugin',          # Perl 6 plugin instance
	_view_notes_btn  => '_view_notes_btn',  # View release notes button
	_install_six_btn => '_install_six_btn', # Install Six button
};

# -- constructor
sub new {
	my ( $class, $plugin, %opt ) = @_;


	# create object
	my $self = $class->SUPER::new(
		$plugin->main,
		-1,
		Wx::gettext('Six Updater'),
		Wx::wxDefaultPosition,
		Wx::wxDefaultSize,
		Wx::wxDEFAULT_FRAME_STYLE | Wx::wxTAB_TRAVERSAL,
	);

	$self->_plugin($plugin);

	# Dialog's icon as is the same as plugin's
	$self->SetIcon( $plugin->logo_icon );

	# create dialog
	$self->_create;

	$self->prepare;

	# fit and center the dialog
	$self->Fit;
	$self->CentreOnParent;

	return $self;
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
	$self->SetSizer( $self->_hbox );
}

#
# create controls in the dialog
#
sub _create_controls {
	my $self = shift;

	# matches result list
	my $label = Wx::StaticText->new(
		$self, -1,
		Wx::gettext('Please select a Six release to install:')
	);
	$self->_list(
		Wx::ListBox->new(
			$self,
			-1,
			Wx::wxDefaultPosition,
			[ 210, -1 ],
			[],
			Wx::wxLB_SINGLE
		)
	);
	
	$self->_progress(
		Wx::Gauge->new(
			$self,
			-1,
			100,
		)
	);

	my $file = File::Spec->catfile( $self->_plugin->_sharedir, 'icons', 'camelia-big.png' );
	my $camelia = Wx::StaticBitmap->new( $self, -1, Wx::Bitmap->new( $file, Wx::wxBITMAP_TYPE_PNG ) );

	my $btn_sizer = Wx::BoxSizer->new(Wx::wxHORIZONTAL);
	$self->_install_six_btn( Wx::Button->new( $self, -1, Wx::gettext('Install Six') ) );
	$self->_view_notes_btn( Wx::Button->new( $self, -1, Wx::gettext('View Release Notes') ) );
	my $cancel_btn = Wx::Button->new( $self, Wx::wxID_CANCEL, Wx::gettext('&Cancel') );

	$btn_sizer->Add( $self->_install_six_btn, 0, Wx::wxALL | Wx::wxEXPAND, 2 );
	$btn_sizer->Add( $self->_view_notes_btn,  0, Wx::wxALL | Wx::wxEXPAND, 2 );
	$btn_sizer->Add( $cancel_btn,             0, Wx::wxALL | Wx::wxEXPAND, 2 );

	my $vbox = Wx::BoxSizer->new(Wx::wxVERTICAL);
	$vbox->Add( $label,       0, Wx::wxALL | Wx::wxEXPAND, 2 );
	$vbox->Add( $self->_list, 1, Wx::wxALL | Wx::wxEXPAND, 2 );
	$vbox->Add( $self->_progress, 0, Wx::wxALL | Wx::wxEXPAND, 2 );
	$vbox->Add( $btn_sizer,   0, Wx::wxALL | Wx::wxEXPAND, 2 );
	$self->_hbox->Add( $vbox,    0, Wx::wxALL | Wx::wxEXPAND, 2 );
	$self->_hbox->Add( $camelia, 0, Wx::wxALL | Wx::wxEXPAND, 2 );

	$self->_setup_events();
}

#
# Adds various events
#
sub _setup_events {
	my $self = shift;

	Wx::Event::EVT_BUTTON(
		$self,
		$self->_view_notes_btn,
		sub {
			my $selection = $self->_list->GetSelection;
			if ( $selection != -1 ) {
				my $release = $self->_list->GetClientData($selection);
				Wx::LaunchDefaultBrowser( $release->{desc_url} );
			}
		},
	);


	Wx::Event::EVT_BUTTON(
		$self,
		$self->_install_six_btn,
		sub {
			my $selection = $self->_list->GetSelection;
			if ( $selection != -1 ) {
				my $release = $self->_list->GetClientData($selection);

				# Show an empty output panel
				$self->_plugin->main->show_output(1);
				$self->_plugin->main->output->Clear;

				$self->_install_six_btn->Enable(0);

				eval {
					#Start the update task in the background
					require Padre::Plugin::Perl6::UpdateTask;
					my $task = Padre::Plugin::Perl6::UpdateTask->new( 
						release => $release,
						progress  => $self->_progress,
					);
					$task->schedule;
				};
				if($@) {
					$self->main->error("Failed to start installation:\n$@");
				}
			}
		},
	);

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
	my $client_data = [ map { $releases->{$_} } sort keys %$releases ];


	#Populate the list box now
	$self->_list->Clear();
	my $pos = 0;
	foreach my $id ( sort keys %$releases ) {
		my $release = $releases->{$id};
		$self->_list->Insert( $release->{name}, $pos, $release );
		$pos++;
	}
	if ( $pos > 0 ) {
		$self->_list->Select(0);
	}
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
