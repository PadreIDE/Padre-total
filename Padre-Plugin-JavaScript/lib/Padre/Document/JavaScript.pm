package Padre::Document::JavaScript;

use 5.008;
use strict;
use warnings;
use Carp            ();
use Padre::Document ();

our $VERSION = '0.23';
our @ISA     = 'Padre::Document';





#####################################################################
# Padre::Document::JavaScript Methods

sub get_functions {
	my $self = shift;
	my $text = $self->text_get;
	
	my %nlCharTable = ( UNIX => "\n", WIN => "\r\n", MAC => "\r" );
	my $nlchar = $nlCharTable{ $self->get_newline_type };
	
	return $text =~ m/${nlchar}function\s+(\w+(?:::\w+)*)/g;
}

sub get_function_regex {
	my ( $self, $sub ) = @_;
	
	my %nlCharTable = ( UNIX => "\n", WIN => "\r\n", MAC => "\r" );
	my $nlchar = $nlCharTable{ $self->get_newline_type };
	
	return qr!(?:^|${nlchar})function\s+$sub\b!;
}

sub comment_lines_str { return '//' }

1;

# Copyright 2008 Gabor Szabo and Fayland Lam
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.
