package Padre::Document::YAML;

# ABSTRACT: YAML document support for Padre

use strict;
use warnings;
use Padre::Document ();

our @ISA = 'Padre::Document';

sub task_functions {
	return '';
}

sub task_outline {
	return '';
}

sub task_syntax {
	return '';
}

sub comment_lines_str {
	return '#';
}

1;
