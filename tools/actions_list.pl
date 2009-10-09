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
use PPI;

our $VERSION = '0.01';

our %actions;

# Override the Padre::Action to capture created actions:

package Padre::Action;

sub new {
	my $class = shift;
	my %data = @_;
	print "Add\n";
	$main::actions{$data{name}} = \%data;
}

package main;

# We don't want any Action module to load the real Action.pm:

opendir my $mod_dir,'lib/Padre/Action' or die 'Error opening Action-dir';
for my $Mod (readdir($mod_dir)) {
	$Mod =~ /\.pm$/ or next;
	print "Load $Mod\n";
	my $Document = PPI::Document->new('lib/Padre/Action/'.$Mod);
	if ( ! defined($Document)) {
		warn 'Error while parsing '.$Mod;
		next;
	}
	my $New_Sub = (@{$Document->find(sub { $_[1]->isa('PPI::Statement::Sub') and ($_[1]->name eq 'new') })})[0];
	eval $New_Sub or warn $@;
}
close $mod_dir;

use Data::Dumper;
print Dumper(\%actions);
