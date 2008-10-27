package Padre::Document::Perl6;

use 5.008;
use strict;
use warnings;
use Padre::Document ();

our $VERSION = '0.14';
our @ISA     = 'Padre::Document';

# Naive way to parse and colourise perl6 files
sub colourise {
	my ($self, $first) = @_;

	$self->remove_color;

	my $editor = $self->editor;
	my $text   = $self->text_get;

	my ($KEYWORD, $STRING, $COMMENT) = (1 .. 5);
	my %regex_of = (
		$KEYWORD  => qr/print|else|say|sub|gt|lt|eq|if/,
		$STRING   => qr/(['"]).*\1/,
		$COMMENT  => qr/#.*/,
	);
	foreach my $color (keys %regex_of) {
		while ($text =~ /$regex_of{$color}/g) {
			my $end    = pos($text);
			my $length = length($&);
			my $start  = $end - $length;
			$editor->StartStyling($start, $color);
			$editor->SetStyling($length, $color);
		}
	}
}

sub remove_color {
	my ($self) = @_;

	my $editor = $self->editor;
	# TODO this is strange, do we reall need to do it with all?
	for my $i (1..5) {
		$editor->StartStyling(0, $i);
		$editor->SetStyling($editor->GetLength, 0);
	}

	return;
}

1;
