package Padre::Plugin::Moose::Main;

use 5.008;
use strict;
use warnings;
use Padre::Plugin::Moose::FBP::Main ();

our $VERSION = '0.95';
our @ISA     = qw{
	Padre::Plugin::Moose::FBP::Main
};

sub on_action_list_selected {
	print "on_action_list_selected\n";
}

sub on_ok_clicked {
	print "on_ok_clicked\n";
}

sub on_cancel_clicked {
	print "on_cancel_clicked\n";
}

1;

# Copyright 2008-2012 The Padre development team as listed in Padre.pm.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.