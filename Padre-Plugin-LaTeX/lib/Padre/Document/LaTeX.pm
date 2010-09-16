package Padre::Document::LaTeX;

use 5.008;
use strict;
use warnings;
use Carp            ();
use Padre::Document ();

our $VERSION = '0.03';
our @ISA     = 'Padre::Document';

sub task_functions {
	return '';
}

sub task_outline {
	return '';
}

sub task_syntax {
	return 'Padre::Document::LaTeX::Syntax';
}

sub comment_lines_str { return '%' }

1;
