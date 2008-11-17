package Padre::Document::JavaScript;

use 5.008;
use strict;
use warnings;
use Carp            ();
use Padre::Document ();
use YAML::Tiny      ();

our $VERSION = '0.16';
our @ISA     = 'Padre::Document';

#####################################################################
# Padre::Document::JavaScript Methods

#my $keywords;
#
#sub keywords {
#	unless ( defined $keywords ) {
#		$keywords = YAML::Tiny::LoadFile(
#			Padre::Wx::sharefile( 'languages', 'perl5', 'javascript.yml' )
#		);
#	}
#	return $keywords;
#}

sub get_functions {
	my $self = shift;
	my $text = $self->text_get;
	return reverse sort $text =~ m{^function\s+(\w+(?:::\w+)*)}gm;
}

sub get_function_regex {
	my ( $self, $sub ) = @_;
	return qr{(^|\n)function\s+$sub\b};
}

#
# $doc->comment_lines($begin, $end);
#
# comment out lines $begin..$end
#
sub comment_lines {
	my ($self, $begin, $end) = @_;

	my $editor = $self->editor;
	for my $line ($begin .. $end) {
		# insert //
		my $pos = $editor->PositionFromLine($line);
		$editor->InsertText($pos, '//');
	}
}

#
# $doc->uncomment_lines($begin, $end);
#
# uncomment lines $begin..$end
#
sub uncomment_lines {
	my ($self, $begin, $end) = @_;

	my $editor = $self->editor;
	for my $line ($begin .. $end) {
		my $first = $editor->PositionFromLine($line);
		my $last  = $first+2;
		my $text  = $editor->GetTextRange($first, $last);
		if ($text eq '//') {
			$editor->SetSelection($first, $last);
			$editor->ReplaceSelection('');
		}
	}
}

1;

# Copyright 2008 Gabor Szabo and Fayland Lam
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.
