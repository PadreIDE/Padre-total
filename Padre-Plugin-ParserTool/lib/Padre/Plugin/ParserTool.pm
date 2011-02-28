package Padre::Plugin::ParserTool;

use 5.008005;
use strict;
use warnings;
use Padre::Plugin ();

our $VERSION = '0.01';
our @ISA     = 'Padre::Plugin';





######################################################################
# Configuration Methods

sub plugin_name {
	'Parser Tool';
}

sub padre_interfaces {
	'Padre::Plugin'   => '0.81',
	'Padre::Document' => '0.81',
	'Padre::Wx'       => '0.81',
}

sub menu_plugins_simple {
	my $self = shift;
	return $self->plugin_name => [
		'Parser Tool' => sub {
			$self->show_dialog;
		},
		'---' => undef,
		'About'   => sub {
			$self->show_about;
		},
	];
}

sub plugin_disable {
	my $self = shift;

	# Unload any child modules we loaded
	$self->unload( qw{
		Padre::Plugin::ParserTool::Dialog
		Padre::Plugin::ParserTool::FBP
	} );

	$self->SUPER::plugin_disable(@_);
}





######################################################################
# Main Methods

sub show_about {
	die "CODE INCOMPLETE";
}

sub show_dialog {
	die "CODE INCOMPLETE";
}

1;
