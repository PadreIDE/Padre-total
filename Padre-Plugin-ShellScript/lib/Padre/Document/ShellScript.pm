package Padre::Document::ShellScript;

# ABSTRACT: Shell script document support for Padre

use 5.008;
use strict;
use warnings;

our @ISA = 'Padre::Document';
use Padre::Document ();

sub get_command {
	my $self = shift;

	my $arg_ref = shift || {};

	my $debug = exists $arg_ref->{debug} ? $arg_ref->{debug} : 0;
	my $trace = exists $arg_ref->{trace} ? $arg_ref->{trace} : 0;

	# TODO get shebang

	# Check the file name
	my $filename = $self->filename;

	my $dir = File::Basename::dirname($filename);
	chdir $dir;
	return $trace
		? qq{"sh" "-xv" "$filename"}
		: qq{"sh" "$filename"};
}

sub comment_lines_str {
	return '#';
}

1;

# Copyright 2008-2011 The Padre development team as listed in Padre.pm.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.
