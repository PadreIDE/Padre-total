package Padre::Plugin::Perl6::Preferences;

use warnings;
use strict;

use Class::XSAccessor accessors => {
	_plugin           => '_plugin',           # plugin to be configured
	_sizer            => '_sizer',            # window sizer
	_colorizer_cb     => '_colorizer_cb',      # colorizer on/off checkbox
	_colorizer_list   => '_colorizer_list',    # colorizer list box
};

our $VERSION = '0.51';

use Padre::Current;
use Padre::Wx ();

use base 'Wx::Dialog';


# -- constructor

sub new {
	my ($class, $plugin) = @_;

	# create object
	my $self = $class->SUPER::new(
		Padre::Current->main,
		-1,
		Wx::gettext('Perl 6 preferences'),
		Wx::wxDefaultPosition,
		Wx::wxDefaultSize,
		Wx::wxDEFAULT_FRAME_STYLE|Wx::wxTAB_TRAVERSAL,
	);
	$self->SetIcon( Wx::GetWxPerlIcon() );
	$self->_plugin($plugin);

	# create dialog
	$self->_create;

	return $self;
}


# -- event handler

#
# $self->_on_ok_button_clicked;
#
# handler called when the ok button has been clicked.
# 
sub _on_ok_button_clicked {
	my $self = shift;
	
	my $plugin = $self->_plugin;

	# read plugin preferences
	my $prefs = $plugin->config;

	# update configuration
	my $old_p6_highlight = $prefs->{p6_highlight};
	my $old_colorizer = $prefs->{colorizer};
	$prefs->{p6_highlight} = $self->_colorizer_cb->GetValue();
	$prefs->{colorizer} = ($self->_colorizer_list->GetSelection() == 0) ? 
		'STD' : 'PGE';

	# store plugin preferences
	$plugin->config_write($prefs);

	if($old_p6_highlight != $prefs->{p6_highlight} || $old_colorizer ne $prefs->{colorizer}) {
		# a configuration change for colorizer
		if( $prefs->{p6_highlight} ) {
			$plugin->highlight;
		}
	}
	
	$self->Destroy;
}


# -- private methods

#
# create the dialog itself.
#
sub _create {
	my $self = shift;

	# create sizer that will host all controls
	my $sizer = Wx::BoxSizer->new( Wx::wxVERTICAL );
	$self->_sizer($sizer);

	# create the controls
	$self->_create_controls;
	$self->_create_buttons;

	# wrap everything in a vbox to add some padding
	$self->SetSizerAndFit($sizer);
	$sizer->SetSizeHints($self);
}

#
# create the buttons pane.
#
sub _create_buttons {
	my $self = shift;
	my $sizer  = $self->_sizer;

	my $butsizer = $self->CreateStdDialogButtonSizer(Wx::wxOK|Wx::wxCANCEL);
	$sizer->Add($butsizer, 0, Wx::wxALL|Wx::wxEXPAND|Wx::wxALIGN_CENTER, 5 );
	Wx::Event::EVT_BUTTON( $self, Wx::wxID_OK, \&_on_ok_button_clicked );
}

#
# create the pane to choose the various configuration parameters.
#
sub _create_controls {
	my $self = shift;

	$self->_colorizer_cb(
		Wx::CheckBox->new( $self, -1, Wx::gettext('Enable coloring'))
	);
	
	my @choices = [
		'S:H:P6/STD',
		'Rakudo/PGE'
	];
	# syntax highligher selection
	my $colorizer_list_label = Wx::StaticText->new( $self, -1, Wx::gettext('Colorizer:') );
	$self->_colorizer_list( 
		Wx::ListBox->new(
			$self,
			-1,
			Wx::wxDefaultPosition,
			[150,50],
			@choices,
		)
	);
	
	# Select based on configuration parameters
	my $config = $self->_plugin->config;
	$self->_colorizer_cb->SetValue( $config->{p6_highlight} );
	$self->_colorizer_list->Select( $config->{colorizer} eq 'STD' ? 0 : 1);
	
	# pack the controls in a box
	my $box;
	$box = Wx::BoxSizer->new(Wx::wxHORIZONTAL);
	$box->Add( $self->_colorizer_cb, 1, Wx::wxALL|Wx::wxEXPAND|Wx::wxALIGN_CENTER, 5 );
	$self->_sizer->Add( $box, 0, Wx::wxALL|Wx::wxEXPAND|Wx::wxALIGN_CENTER, 5 );

	$box = Wx::BoxSizer->new(Wx::wxHORIZONTAL);
	$box->Add( $colorizer_list_label, 0, Wx::wxALL|Wx::wxEXPAND|Wx::wxALIGN_CENTER, 5 );
	$box->Add( $self->_colorizer_list, 1, Wx::wxALL|Wx::wxEXPAND|Wx::wxALIGN_CENTER, 5 );
	$self->_sizer->Add( $box, 0, Wx::wxALL|Wx::wxEXPAND|Wx::wxALIGN_CENTER, 5 );

}


1;

__END__

=head1 AUTHOR

Ahmad M. Zawawi, C<< <ahmad.zawawi at gmail.com> >>

Gabor Szabo L<http://szabgab.com/>

=head1 COPYRIGHT AND LICENSE

Copyright 2008-2009 Padre Developers as in Perl6.pm

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl 5 itself.