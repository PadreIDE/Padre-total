package Padre::Wx::Dialog::Preferences::Keys;

# Modify key bindings

=pod

=head1 NAME

Padre::Wx::Dialog::Preferences::Keys - Config key bindings

=head1 DESCRIPTION

C<Padre::Wx::Dialog::Preferences::Keys> Configure key bindings

=head1 METHODS

=cut

use 5.008;
use strict;
use warnings;
use Params::Util qw{_STRING};
use Padre::Current               ();
use Padre::DB                    ();
use Padre::Wx                    ();
use Wx::Event qw(:everything);
use Padre::Wx::Role::MainChild   ();

our $VERSION = '0.42';
our @ISA     = qw{
	Padre::Wx::Role::MainChild
	Wx::Dialog
};

use Class::XSAccessor getters => {
		tree   => 'tree',
		sequence => 'sequence',
	},
	accessors => {
		config          => 'config',
	};

=pod

=head2 new

  my $keys = Padre::Wx::Dialog::Preferences::Keys->new($main)

Create and return a C<Padre::Wx::Dialog::Preferences::Keys> widget.

=cut

sub new {
	my $class = shift;
	my $main  = shift;
	unless ($main) {
		die("Did not pass parent to find dialog constructor");
	}

	# Create the Wx dialog
	my $self = $class->SUPER::new(
		$main,
		-1,
		Wx::gettext('Shortcuts/Key bindings'),
		Wx::wxDefaultPosition,
		Wx::wxDefaultSize,
		Wx::wxCAPTION | Wx::wxCLOSE_BOX | Wx::wxSYSTEM_MENU | Wx::wxRESIZE_BORDER
	);

	$self->{tree} = Padre::Wx::Directory::TreeCtrl->new($self);
	$self->{tree}->SetSize(350,350);
        $self->{sequence} = Wx::TextCtrl->new($self, -1, '', Wx::wxDefaultPosition, Wx::wxDefaultSize);

	# Update the dialog from configuration
	$self->{config} = $self->current->config;

	$self->_create_tree;

	$self->Show(1);

#use Data::Dumper;
#print STDERR Dumper(Padre::Wx::Menubar->wx)."\n";

	return $self;
}

sub search {
	undef;
}

sub _create_tree {
	my $self = shift;
	
	# Gets Root node
	my $root = $self->tree->GetRootItem;

	print STDERR "Start\n";
	print STDERR Padre::Wx::Menubar->wx."\n";

	for (Padre::Wx::Menubar->wx->GetMenuItems) {
		print STDERR "$_\n";
		print STDERR "   $_->[0] / $_->[1]\n";
		my $new_elem = $self->tree->AppendItem(
			$root,
			$_->[1],
			-1,
			-1,
			Wx::TreeItemData->new(
				{   name => $_->[1],
					dir  => '/tmp',
					type => 'folder',
				}
			)
		);
		$self->tree->SetItemHasChildren( $new_elem, 1 );
		$self->tree->Expand( $new_elem );
	}

		my $new_elem = $self->tree->AppendItem(
			$root,
			'Name1a',
			-1,
			-1,
			Wx::TreeItemData->new(
				{   name => 'Name1b',
					dir  => '/tmp',
					type => 'folder',
				}
			)
		);
		$self->tree->SetItemHasChildren( $new_elem, 1 );
		$self->tree->Expand( $new_elem );
		my $new_elem2 = $self->tree->AppendItem(
			$new_elem,
			'Name2a',
			-1,
			-1,
			Wx::TreeItemData->new(
				{   name => 'Name2b',
					dir  => '/tmp',
					type => 'folder',
				}
			)
		);
		$self->tree->SetItemHasChildren( $new_elem2, 1 );
for (1..3) {
		my $new_elem3 = $self->tree->AppendItem(
			$new_elem,
			'Name2a',
			'1',
			-1,
			Wx::TreeItemData->new(
				{   name => 'Name2b',
					dir  => '/tmp',
					type => 'folder',
				}
			)
		);
}
#		if ( $->{type} eq 'folder' ) {
#			$self->SetItemHasChildren( $new_elem, 1 );
#		}
}

=pod

=head2 cancel

  $self->cancel

Hide dialog when pressed cancel button.

=cut

sub cancel {
	my $self = shift;
	$self->Hide;

	my $editor = $self->current->editor;
	if ($editor) {
		$editor->SetFocus;
	}

	return;
}

#####################################################################
# Support Methods

# Save the dialog settings to configuration. Returns the config object
# as a convenience.
sub _sync_config {
	my $self = shift;

	# Save the search settings to config only if at least one of them has changed
	my $config = $self->current->config;
	my $Changed = 0;
	for ('find_case','find_regex','find_first','find_reverse') {
	 next if $config->$_ == $self->{$_}->GetValue;
	 $config->set( $_    => $self->{$_}->GetValue );
	 $Changed = 1;
	}
	$config->write;

	return $config;
}

1;

=pod

=head1 COPYRIGHT & LICENSE

Copyright 2008-2009 The Padre development team as listed in Padre.pm.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut

# Copyright 2008-2009 The Padre development team as listed in Padre.pm.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.
