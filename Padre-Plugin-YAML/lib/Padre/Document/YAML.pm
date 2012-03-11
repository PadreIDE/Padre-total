package Padre::Document::YAML;

# ABSTRACT: YAML document support for Padre
use 5.010001;
use strict;
use warnings;

use Padre::Document ();

our $VERSION = '0.02';
use parent qw(Padre::Document);


sub task_functions {
	return '';
}

sub task_outline {
	return '';
}

sub task_syntax {
	return 'Padre::Document::YAML::Syntax';
}

sub comment_lines_str {
	return '#';
}

1;

__END__

