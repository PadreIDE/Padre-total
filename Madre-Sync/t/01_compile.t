#!/usr/bin/perl

use 5.008;
use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}
use Test::More tests => 7;

use_ok( 'Madre::Sync' );

no strict 'refs';
is(
	$Madre::Sync::VERSION,
	${"Madre::Sync::${_}::VERSION"},
	"Madre::Sync::$_ loaded",
) foreach qw{
	Schema
	View::TT
	Model::padreDB
	Controller::Root
	Controller::User
	Controller::Conf
};
