package Padre::Plugin;

=pod

=head1 NAME

Padre::Plugin - Padre Plugin API 

=head SYNOPSIS

  package Padre::Plugin::Foo;
  
  use strict;
  use base 'Padre::Plugin';
  
  # Declare the Padre classes we use and Padre version the code was written to
  sub padre_interfaces {
      'Padre::Document::Perl' => 0.16,
      'Padre::Wx::MainWindow' => 0.16,
      'Padre::DB'             => 0.16,
  }
  
  # The plugin name to show in the Plugins menu
  sub plugins_menu_label {
  	  'Sample Plugin'
  }
  
  # The command structure to show in the Plugins menu
  sub plugins_menu_data {
  	  ...
  }
  
  1;

=cut

use 5.008;
use strict;
use warnings;
use Scalar::Util ();
use Padre::Wx    ();

our $VERSION = '0.16';





######################################################################
# Default Constructor

sub new {
	my $class = shift;
	my $self  = bless { @_ }, $class;
	return $self;
}

# By default we use no interfaces.
# This is of course a lie, but makes it easier in the short term
sub padre_interfaces {
	return ();
}

# Runs when the plugin is started
sub plugin_start {
	return 1;
}

sub plugin_stop {
	return 1;
}

# Default plugins menu label
sub menu_plugins_label {
	my $self  = shift;
	my $label = Scalar::Util::blessed($self);
	$label =~ s/^Padre::Plugin:://;
	return $label;
}

# Default plugins menu data
sub menu_plugins_data {
	# Plugins returning no data will not
	# be visible in the plugin menu.
	return ();
}

# Generates plugin menu
sub menu_plugins {
	my $self   = shift;
	my $parent = shift;
	
}

sub _menu_plugins_items {
	my $self  = shift;
	my $items = shift;
	my ($self, $items) = @_;

	my $menu = Wx::Menu->new;
	foreach my $item ( @items ) {
		if (ref $m->[1] eq 'ARRAY') {
			my $submenu = $self->add_plugin_menu_items($m->[1]);
			$menu->Append(-1, $m->[0], $submenu);
		} else {
			Wx::Event::EVT_MENU( $self->win, $menu->Append(-1, $m->[0]), $m->[1] );
		}
	}

	return $menu;
}

1;
