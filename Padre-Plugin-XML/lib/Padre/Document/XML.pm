package Padre::Document::XML;

use 5.008;
use strict;
use warnings;
use Padre::Document ();

our $VERSION = '0.10';
our @ISA     = 'Padre::Document';


sub task_functions {
	return '';
}

sub task_outline {
	return '';
}

sub task_syntax {
	return 'Padre::Document::XML::Syntax';
}

sub comment_lines_str {
	return [ '<!--', '-->' ];
}

1;
