#!/usr/bin/perl
=pod

=head1 NAME

actions_list.pl - Create a list of Padre Actions

=head1 SYNOPSIS

	actions_list.pl --text
	actions_list.pl --html

=head1 DESCRIPTION

This script creates a list of all actions supported by Padre
and outputs it in text or HTML-format. The default is text format.

=cut

use 5.006;
use strict;
use warnings;

our $VERSION = '0.01';

our %actions;

# Override the Padre::Action to capture created actions:

package Padre::Action;

sub new {
	my $class = shift;
	my %data = @_;
	
	$main::actions{$data{name}} = \%data;
}

package main;

# We don't want any Action module to load the real Action.pm:

opendir my $mod_dir,'lib/Padre/Action' or die 'Error opening Action-dir';
for my $Mod (readdir($mod_dir)) {
	$Mod =~ s/\.pm$// or next;
	print "Load $Mod\n";
	print '$Padre::Action::'.$Mod.'::INC{"Padre/Action.pm"} = "internal";'."\n";
	eval '$Padre::Action::'.$Mod.'::INC{"Padre/Action.pm"} = "internal";';
	require 'lib/Padre/Action/'.$Mod.'.pm';
	$Mod = 'Padre::Action::'.$Mod;
	$Mod->new();
}
close $mod_dir;

use Data::Dumper;
print Dumper(\%actions);
