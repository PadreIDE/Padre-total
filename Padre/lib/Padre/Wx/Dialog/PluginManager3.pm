package Padre::Wx::Dialog::PluginManager3;

# Third-generation plugin manager

use strict;
use warnings;

use Carp                    qw{ croak };
use Class::XSAccessor
	accessors => {
		_hbox      => '_hbox',
		_imagelist => '_imagelist',
		_list      => '_list',
		_manager   => '_manager',
	};

use Padre::Wx::Icon;

use base 'Wx::Frame';

our $VERSION = '0.30';


# -- constructor

sub new {
	my ($class, $parent, $manager) = @_;

	# create object
	my $self = $class->SUPER::new(
		$parent,
		-1,
		Wx::gettext('Plugin Manager'),
		Wx::wxDefaultPosition,
		Wx::wxDefaultSize,
		Wx::wxDEFAULT_FRAME_STYLE,
	);

	# store plugin manager
	croak "Missing or invalid Padre::PluginManager object"
		unless $manager->isa('Padre::PluginManager');
	$self->_manager( $manager );

	# create dialog
	$self->_create;

	return $self;
}


# -- public methods

sub show {
	my $self = shift;
	$self->_refresh;
	$self->Show;
}


# -- private methods

sub _create {
	my $self = shift;
	
	# create vertical box that will host all controls
	my $hbox = Wx::BoxSizer->new( Wx::wxHORIZONTAL );
	$self->SetSizer($hbox);
	$self->SetMinSize([640,480]);
	$self->_hbox( $hbox );

	$self->_create_list;
	$self->_create_right_pane;
}


sub _create_list {
	my $self = shift;
	
	# create list
	my $list = Wx::ListView->new(
		$self,
		-1,
		Wx::wxDefaultPosition,
		Wx::wxDefaultSize,
		Wx::wxLC_REPORT | Wx::wxLC_SINGLE_SEL,
	);
	$list->InsertColumn( 0, Wx::gettext('Name') );
	$list->InsertColumn( 1, Wx::gettext('Version') );
	$list->InsertColumn( 2, Wx::gettext('Status') );
	$self->_list( $list );

	# create imagelist
	my $imglist = Wx::ImageList->new( 16, 16 );
	$list->AssignImageList($imglist, Wx::wxIMAGE_LIST_SMALL);
	$self->_imagelist( $imglist );

	# pack the list
	$self->_hbox->Add( $list, 0, Wx::wxALL | Wx::wxEXPAND, 1 );
}


#
# $dialog->_create_right_pane;
#
# create the right pane of the frame. it will hold the name of the plugin,
# the associated documentation, and the action buttons to manage the plugin.
#
# no params. no return values.
#
sub _create_right_pane {
	my $self = shift;

	# all controls will be lined up in a vbox
	my $vbox = Wx::BoxSizer->new( Wx::wxVERTICAL );
	$self->_hbox->Add( $vbox, 1, Wx::wxALL | Wx::wxEXPAND, 1 );

	# the plugin name
	my $label = Wx::StaticText->new( $self, -1,
		'plugin name',
		Wx::wxDefaultPosition,
		Wx::wxDefaultSize,
		Wx::wxALIGN_CENTRE | Wx::wxST_NO_AUTORESIZE,
	);
	$vbox->Add($label, 0, Wx::wxALIGN_CENTER, 1);
	my $font = $label->GetFont;
	$font->SetWeight(Wx::wxFONTWEIGHT_BOLD);
	$font->SetPointSize( $font->GetPointSize + 2 );
	$label->SetFont($font);
	
	# the plugin documentation
	my $whtml = Wx::HtmlWindow->new( $self );
	$vbox->Add($whtml, 1, Wx::wxALL | Wx::wxALIGN_TOP |
		Wx::wxALIGN_CENTER_HORIZONTAL | Wx::wxEXPAND, 1);

	# the buttons
	my $hbox = Wx::BoxSizer->new( Wx::wxHORIZONTAL );
	$vbox->Add( $hbox, 0, Wx::wxALL | Wx::wxEXPAND, 1 );
	my $b1 = Wx::Button->new( $self, -1, 'Button 1' );
	my $b2 = Wx::Button->new( $self, -1, 'Button 2' );
	$hbox->AddStretchSpacer;
	$hbox->Add($b1, 0, Wx::wxALL, 1);
	$hbox->AddStretchSpacer;
	$hbox->Add($b2, 0, Wx::wxALL, 1);
	$hbox->AddStretchSpacer;
}



#
# $dialog->_refresh;
#
# refresh list of plugins and their associated state.
#
sub _refresh {
	my $self = shift;

	my $list    = $self->_list;
	my $manager = $self->_manager;
	my $plugins = $manager->plugins;
	my $imglist = $self->_imagelist;

	# clear image list & fill it again
	$imglist->RemoveAll;
	# default plugin icon
	$imglist->Add( Padre::Wx::Icon::find('status/padre-plugin') );
	my %icon = ( plugin => 0 );
	# plugin status
	my $i = 0;
	foreach my $name ( qw{ enabled disabled crashed incompatible } ) {
		my $icon = Padre::Wx::Icon::find("status/padre-plugin-$name");
		$imglist->Add($icon);
		$icon{$name} = ++$i;
	}
	
	# clear plugin list & fill it again
	$list->DeleteAllItems;
	foreach my $name ( reverse $manager->plugin_names ) {
		my $plugin  = $plugins->{$name};
		my $version = $plugin->version || '???';

		my $status = Wx::gettext('disabled');
		$status    = Wx::gettext('enabled')      if $plugin->enabled;
		$status    = Wx::gettext('incompatible') if $plugin->incompatible;
		$status    = Wx::gettext('crashed')      if $plugin->error;

		my $idx = $list->InsertStringImageItem(0, $name, 0);
		$list->SetItem($idx, 1, $version);
		$list->SetItem($idx, 2, $status, $icon{$status});
		$list->SetItemData( $idx, 1 );
	}

	# auto-resize columns
	$list->SetColumnWidth($_, Wx::wxLIST_AUTOSIZE) for 0..2;

	# making sure the list can show all columns
	my $width = 15; # taking vertical scrollbar into account
	$width += $list->GetColumnWidth($_) for 0..2;
	$list->SetMinSize([$width, -1]);
}


1;

__END__


=head1 NAME

Padre::Wx::Dialog::PluginManager3 - Plugin manager dialog for Padre



=head1 DESCRIPTION

Padre will have a lot of plugins. First plugin manager was not taking this
into account, and the first plugin manager window was too small & too
crowded to show them all properly.

This revamped plugin manager is now using a list control, and thus can show
lots of plugins in an effective manner.



=head1 PUBLIC API

=head2 Constructor

=over 4

=item * my $dialog = P::W::D::PM->new( $parent, $manager )

Create and return a new Wx dialog listing all the plugins. It needs a
C<$parent> window and a C<Padre::PluginManager> object that really handles
Padre plugins under the hood.


=back



=head2 Public methods

=over 4

=item * $dialog->show;

Request the plugin manager dialog to be shown. It will be refreshed first
with a current list of plugins with their state.


=back



=head1 COPYRIGHT & LICENSE

Copyright 2008-2009 The Padre development team as listed in Padre.pm.

This program is free software; you can redistribute it and/or modify it under the
same terms as Perl 5 itself.


=cut


# Copyright 2008-2009 The Padre development team as listed in Padre.pm.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.
