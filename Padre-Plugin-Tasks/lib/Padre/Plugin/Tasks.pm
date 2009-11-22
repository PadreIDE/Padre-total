package Padre::Plugin::Tasks;

use 5.008;
use warnings;
use strict;

use Padre::Config ();
use Padre::Wx     ();
use Padre::Plugin ();
use Padre::Util   ('_T');

our $VERSION = '0.01';
our @ISA     = 'Padre::Plugin';

=head1 NAME

Padre::Plugin::Tasks - Tasks management system embedded in Padre

=head1 SYNOPSIS

cpan install Padre::Plugin::Tasks

=head1 DESCRIPTION

TODO plugin

Personal TODO list, start by adding and prioritizing items in a 
private TODO list saved in a local database. Allow the user to 
associate each TODO item with a certain project. 
Each item might have sub-items.

plan:
  id
  time_added
  title
  checkbox done
  time_done
  association ("local", or connection to external system)

  id_of_item_before (for ordering)
  id_of_parent (for hierarchy)
  
  restriction: the parent of the item before must be the same a the 
  parent of this item.
  
=head2 RT integration

Integrate with rt.cpan.org, allow the user to configure a CPAN id
and monitor the rt queue of that CPAN id.

=head2 Trac integration

Add the capability to talk to various bug-tracking systems starting 
by trac as that's what we are using. 
Fetch the list of entries (associated with my users).

Local capabilities:
Allow prioritizing the items for myself. Allow adding sub-items
Allow some changes to be made to the actual items and later sync 
them back to the server.

=head1 Stand Alone version

Check how easy or hard it would be to create a stand alone version of this
TODO list tool, one that does not require Padre to be installed
and maybe not even a threaded perl.


=head1 AUTHOR

Gabor Szabo, C<< <szabgab at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to L<http://padre.perlide.org/>


=head1 COPYRIGHT & LICENSE

Copyright 2008-2009 The Padre development team as listed in Padre.pm.
all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

#####################################################################
# Padre::Plugin Methods

sub padre_interfaces {
	'Padre::Plugin' => 0.42;
}

sub plugin_name {
	'Tasks';
}

sub menu_plugins_simple {
	my $self = shift;
	return $self->plugin_name => [
		_T('About') => sub { $self->show_about },
		_T('Open Tasks Window') => \&on_show_window,
		
	];
}

#####################################################################
# Custom Methods

sub on_show_window {
	my $self = shift;
	my $event = shift;

	require Padre::Plugin::Tasks::Dialog;
	Padre::Plugin::Tasks::Dialog->show;
}

sub show_about {
	my $self = shift;

	# Generate the About dialog
	my $about = Wx::AboutDialogInfo->new;
	$about->SetName("Padre::Plugin::Tasks");
	$about->SetDescription( <<"END_MESSAGE" );
Embedded Tasks support (TODO list) for Padre
END_MESSAGE
	$about->SetVersion($VERSION);

	# Show the About dialog
	Wx::AboutBox($about);

	return;
}

1;

