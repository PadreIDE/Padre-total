package Padre::Plugin::JavaScript::Document;

use 5.008;
use strict;
use warnings;
use Carp            ();
use Padre::Document ();

our $VERSION = '0.24';
our @ISA     = 'Padre::Document';





#####################################################################
# Padre::Document::JavaScript Methods

# Copied from Padre::Document::Perl
sub get_functions {
	my $self = shift;
	my $text = $self->text_get;
	return $text =~ m/[\012\015]function\s+(\w+(?:::\w+)*)/g;
}

sub get_function_regex {
	return qr/(?:(?<=^)function\s+$_[1]|(?<=[\012\0125])function\s+$_[1])\b/;
}

sub comment_lines_str { return '//' }

1;

# Copyright 2008 Gabor Szabo and Fayland Lam
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.
