#!/usr/bin/perl

=pod

=head1 NAME

actions_list.pl - Create a list of Padre Actions

=head1 SYNOPSIS

	actions_list.pl --text actions.dump
	actions_list.pl --html actions.dump

=head1 DESCRIPTION

This script creates a list of all actions supported by Padre
and outputs it in text or HTML-format. The default is text format.

=head1 USAGE

Set the environment variable PADRE_EXPORT_ACTIONS to 1 and then
run Padre.

	PADRE_EXPORT_ACTIONS=1 ./dev.pl

It will create a actions.dump - file in your config dir
(usually ~/.padre on Linux). Just pass this file to actions_list.pl

=cut

use 5.006;
use strict;
use warnings;

our $VERSION = '0.03';

package Local::Output::Text;

sub start {
	my $self = shift;
}

sub action {
	my $self   = shift;
	my $action = shift;
	print "***** " . $action->{name} . " *****\n";
	print 'Default shortcut: ' . $action->{shortcut} . "\n" if defined( $action->{shortcut} );
	print $action->{comment} . "\n" if defined( $action->{comment} );
	print "\n";
}

sub finish {
	my $self = shift;
}




package Local::Output::HTML;

sub start {
	my $self = shift;
	print <<_EOT_;
<html><body><table border=1>
<th><td>Action</td><td>Default<br>shortcut</td><td>Comment</td></th>
_EOT_
}

sub action {
	my $self   = shift;
	my $action = shift;
	print '<tr>' . '<td>'
		. $action->{name} . '</td>' . '<td>'
		. ( defined( $action->{shortcut} ) ? $action->{shortcut} : '' ) . '</td>' . '<td>'
		. ( defined( $action->{comment} )  ? $action->{comment}  : '' ) . '</td>'
		. "</tr>\n";
}

sub finish {
	my $self = shift;
	print '</table></body></html>';
}




my %actions;
our $VAR1;

my $Formatter = 'Local::Output::Text';

for (@ARGV) {
	if ( $_ eq '--text' ) {
		$Formatter = 'Local::Output::Text';
		next;
	} elsif ( $_ eq '--html' ) {
		$Formatter = 'Local::Output::HTML';
		next;
	}

	require $_;

	for ( keys( %{$VAR1} ) ) {
		$actions{$_} = $VAR1->{$_};
	}
}

$Formatter->start;

for ( sort( keys(%actions) ) ) {
	$Formatter->action( $actions{$_} );
}

$Formatter->finish;
