package Padre::Plugin::Perl6::Preferences;

use warnings;
use strict;

use Class::XSAccessor accessors => {
    _plugin      => '_plugin',       # plugin to be configured
    _sizer       => '_sizer',        # window sizer
};

our $VERSION = '0.37';

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
        'Perl6 preferences',
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
    my ($self) = @_;
    my $plugin = $self->_plugin;

    # read plugin preferences
    #my $prefs = $plugin->config;

    # overwrite dictionary preference
    #my $dic = $self->_dict_combo->GetValue;
    #$prefs->{dictionary} = $dic;

    # store plugin preferences
    #$plugin->config_write($prefs);
    
    $self->Destroy;
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
# $dialog->_create_buttons;
#
# create the buttons pane.
#
# no params. no return values.
#
sub _create_buttons {
    my ($self) = @_;
    my $sizer  = $self->_sizer;

    my $butsizer = $self->CreateStdDialogButtonSizer(Wx::wxOK|Wx::wxCANCEL);
    $sizer->Add($butsizer, 0, Wx::wxALL|Wx::wxEXPAND|Wx::wxALIGN_CENTER, 5 );
    Wx::Event::EVT_BUTTON( $self, Wx::wxID_OK, \&_on_ok_button_clicked );
}

#
# $dialog->_create_controls;
#
# create the pane to choose the various configuration parameters.
#
# no params. no return values.
#
sub _create_controls {
    my ($self) = @_;

    # syntax highligher selection
    my $label0 = Wx::StaticText->new( $self, -1, 'Syntax Highlighting Engine:' );
    my $field0 = Wx::ListCtrl->new(
        $self,
		-1,
		Wx::wxDefaultPosition,
		Wx::wxDefaultSize,
		Wx::wxLC_SINGLE_SEL | Wx::wxLC_NO_HEADER | Wx::wxLC_REPORT | Wx::wxBORDER_NONE,
    );
    
	# Set up one column and populate it
	$field0->InsertColumn( 0, 'TEST' );
	$field0->SetColumnWidth( 0, 100);
    my $item;
    $item = Wx::ListItem->new;
    $item->SetText('S:H:P6/STD');
    $field0->InsertItem($item);
    $item = Wx::ListItem->new;
    $item->SetText('Rakudo/PGE');
    $field0->InsertItem($item);

    # mildew directory
    my $mildew_dir_label = Wx::StaticText->new( $self, -1, 'mildew directory:' );
    my $mildew_dir_text = Wx::TextCtrl->new(
        $self,
        -1,
        '',
    );
    my $mildew_dir_picker = Wx::DirPickerCtrl->new(
        $self,
        -1,
        'Pick mildew Directory',
    );

    # rakudo directory
    my $rakudo_dir_label = Wx::StaticText->new( $self, -1, 'rakudo directory:' );
    my $rakudo_dir_text = Wx::TextCtrl->new(
        $self,
        -1,
        '',
    );
    my $rakudo_dir_picker = Wx::DirPickerCtrl->new(
        $self,
        -1,
        'Pick rakudo Directory',
    );

    # pack the controls in a box
    my $box;
    $box = Wx::BoxSizer->new(Wx::wxHORIZONTAL);
    $box->Add( $label0, 0, Wx::wxALL|Wx::wxEXPAND|Wx::wxALIGN_CENTER, 5 );
    $box->Add( $field0, 1, Wx::wxALL|Wx::wxEXPAND|Wx::wxALIGN_CENTER, 5 );
    $self->_sizer->Add( $box, 0, Wx::wxALL|Wx::wxEXPAND|Wx::wxALIGN_CENTER, 5 );

    $box = Wx::BoxSizer->new(Wx::wxHORIZONTAL);
    $box->Add( $mildew_dir_label, 0, Wx::wxALL|Wx::wxEXPAND|Wx::wxALIGN_CENTER, 5 );
    $box->Add( $mildew_dir_text, 1, Wx::wxALL|Wx::wxEXPAND|Wx::wxALIGN_CENTER, 5 );
    $box->Add( $mildew_dir_picker, 1, Wx::wxALL|Wx::wxEXPAND|Wx::wxALIGN_CENTER, 5 );
    $self->_sizer->Add( $box, 0, Wx::wxALL|Wx::wxEXPAND|Wx::wxALIGN_CENTER, 5 );

    $box = Wx::BoxSizer->new(Wx::wxHORIZONTAL);
    $box->Add( $rakudo_dir_label, 0, Wx::wxALL|Wx::wxEXPAND|Wx::wxALIGN_CENTER, 5 );
    $box->Add( $rakudo_dir_text, 1, Wx::wxALL|Wx::wxEXPAND|Wx::wxALIGN_CENTER, 5 );
    $box->Add( $rakudo_dir_picker, 1, Wx::wxALL|Wx::wxEXPAND|Wx::wxALIGN_CENTER, 5 );
    $self->_sizer->Add( $box, 0, Wx::wxALL|Wx::wxEXPAND|Wx::wxALIGN_CENTER, 5 );
}


1;

# Copyright 2008-2009 Ahmad M. Zawawi and Gabor Szabo.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.