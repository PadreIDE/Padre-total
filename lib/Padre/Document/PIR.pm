package Padre::Document::PIR;

use 5.008;
use strict;
use warnings;
use Carp ();
use Params::Util '_INSTANCE';
use Padre::Document ();
use Padre::Util ();

our $VERSION = '0.25';
our @ISA     = 'Padre::Document';

# Naive way to parse and colorize pir files
sub colorize {
	my ( $self, $first ) = @_;

	my $doc = Padre::Current->document;
	Padre::Util::debug(__PACKAGE__ . " colorize called (self: $self) (doc: $doc)");

	$doc->remove_color;

	my $editor = $doc->editor;
	Padre::Util::debug('done');
	my $text   = $doc->text_get;
	Padre::Util::debug("text to colorize: $text");

	#	my @lines = split /\n/, $text;
	#	foreach my $line (@lines) {
	#		if ($line =~ //) {
	#		}
	#	}

	my ( $KEYWORD, $REGISTER, $LABEL, $DIRECTIVES, $STRING, $COMMENT ) = ( 1 .. 6 );
	my %regex_of = (
		$KEYWORD    => qr/\b(print|branch|new|set|end|sub|abs|gt|lt|eq)\b/,
		$REGISTER   => qr/I0|N\d+/,
		$LABEL      => qr/^\w*:/m,
		$STRING     => qr/(['"]).*\1/,
		$COMMENT    => qr/#.*/,
		$DIRECTIVES => qr/\.\w+/m,
	);
	foreach my $color ( keys %regex_of ) {
		while ( $text =~ /$regex_of{$color}/g ) {
			my $end    = pos($text);
			my $length = length($&);
			my $start  = $end - $length;
			Padre::Util::debug("start: $start, length: $length, end: $end");
			$editor->StartStyling( $start, $color );
			$editor->SetStyling( $length, $color );
		}
	}
}

sub comment_lines_str { return '#' }

1;

# Copyright 2008 Gabor Szabo.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.
