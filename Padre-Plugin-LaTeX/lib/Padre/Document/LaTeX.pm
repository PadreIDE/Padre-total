package Padre::Document::LaTeX;

# ABSTRACT: Latex support document for Padre

use 5.008;
use strict;
use warnings;
use Carp            ();
use Padre::Document ();

our @ISA = 'Padre::Document';

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
