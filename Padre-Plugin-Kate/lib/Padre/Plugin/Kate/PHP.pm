package Padre::Plugin::Kate::PHP;

use 5.008;
use strict;
use warnings;
use Carp ();
use Params::Util '_INSTANCE';
use Padre::Current;

our $VERSION = '0.01';

use Syntax::Highlight::Engine::Kate::All;
use Syntax::Highlight::Engine::Kate;

sub colorize {
	my ( $self, $first ) = @_;

	my $doc = Padre::Current->document;
	# TODO we might need not remove all the color, just from a certain section
	# TODO reuse the $first passed to the method
	$doc->remove_color;

	my $editor = $doc->editor;
	my $text   = $doc->text_get;

	my $kate = Syntax::Highlight::Engine::Kate->new(
		language => 'Perl',
	);

	# returns a list of pairs: string, type
	my @tokens = $kate->highlight($text);
	my %COLOR = (
		Normal => 0,
		Operator => 1,
		String => 2,
		Function => 3,
		DataType => 4,
		Variable => 5,
		Float => 6,
		Keyword => 7,
		Char => 8,
		Comment => 9,
	);

	my $start = 0;
	my $end   = 0;
	while (@tokens) {
		my $string = shift @tokens;
		my $type   = shift @tokens;
		#$type ||= 'Normal';
		#print "'$string'    '$type'\n";
		my $color = $COLOR{$type};
		if (not defined $color) {
			warn "Missing color definition for type '$type'\n";
			$color = 0;
		}
		my $length = length($string);
		#$end += $length;
		$editor->StartStyling( $start, $color );
		$editor->SetStyling( $length, $color );
		#$start = $end;
		$start += $length;
	}
	return;
}


1;

# Copyright 2008 Gabor Szabo.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.
