package Padre::Document::ShellScript;

use 5.008;
use strict;
use warnings;
use Padre::Document ();

our $VERSION = '0.02';
our @ISA     = 'Padre::Document';

sub get_command {
	my $self  = shift;
	my $debug = shift;

	# TODO get shebang

	# Check the file name
	my $filename = $self->filename;

	my $dir = File::Basename::dirname($filename);
	chdir $dir;
	return $debug
		? qq{"sh" "-xv" "$filename"}
		: qq{"sh" "$filename"};
}

sub comment_lines_str {
	return '#';
}

1;

# Copyright 2008-2010 The Padre development team as listed in Padre.pm.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.
