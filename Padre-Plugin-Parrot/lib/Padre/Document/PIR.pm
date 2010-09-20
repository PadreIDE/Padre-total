package Padre::Document::PIR;

use 5.008;
use strict;
use warnings;

use Carp ();
use Params::Util '_INSTANCE';
use Padre::Logger;
use Padre::Document ();
use Padre::Util     ();
use Padre::Constant;

our $VERSION = '0.27';
our @ISA     = 'Padre::Document';

# Naive way to parse and colorize pir files
sub colorize {
	my ( $self, $first ) = @_;

	my $doc = Padre::Current->document;
	TRACE( __PACKAGE__ . " colorize called (self: $self) (doc: $doc)" ) if DEBUG;

	$doc->remove_color;

	my $editor = $doc->editor;
	TRACE('done') if DEBUG;
	my $text = $doc->text_get;
	TRACE("text to colorize: $text") if DEBUG;

	#	my @lines = split /\n/, $text;
	#	foreach my $line (@lines) {
	#		if ($line =~ //) {
	#		}
	#	}

	my ( $KEYWORD, $REGISTER, $LABEL, $DIRECTIVES, $STRING, $COMMENT ) = ( 1 .. 6 );
	my %regex_of = (
		$KEYWORD    => qr/\b(print|branch|goto|say|new|set|end|sub|abs|add|inc|mul|if|gt|lt|le|ge|eq)\b/,
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
			TRACE("start: $start, length: $length, end: $end") if DEBUG;
			$editor->StartStyling( $start, $color );
			$editor->SetStyling( $length, $color );
		}
	}
}

sub comment_lines_str { return '#' }

# TODO: better error indication in case we cannot return a command
sub get_command {
	my ($self) = @_;

	return if not $ENV{PARROT_DIR};
	my $parrot = "$ENV{PARROT_DIR}/parrot" . ( Padre::Constant::WIN32 ? '.exe' : '' );

	return if not -e $parrot;
	my $filename = $self->filename;
	return if not $filename;

	return "$parrot $filename";
}

sub pir2pbc {
	my ($self) = @_;

	return if not $ENV{PARROT_DIR};
	my $parrot = "$ENV{PARROT_DIR}/parrot" . ( Padre::Constant::WIN32 ? '.exe' : '' );

	return if not -e $parrot;
	my $filename = $self->filename;
	return if not $filename or $filename !~ /\.pir$/i;


	my $outfile = substr( $filename, 0, -3 ) . 'pbc';

	my $cmd = "$parrot -o $outfile $filename";

	#my $main = Padre->ide->wx->main;
	#$main->message($cmd);
	system $cmd;
}

sub get_help_provider {
	require Padre::HelpProvider::PIR;
	return Padre::HelpProvider::PIR->new;
}

1;

__END__

=head1 NAME

Padre::Plugin::Document::PIR - Padre PIR Document

=head1 AUTHOR

Gabor Szabo L<http://szabgab.com/>

Ahmad M. Zawawi C<< <ahmad.zawawi at gmail.com> >>

=head1 COPYRIGHT AND LICENSE

Copyright 2008-2010 Padre Developers as in Parrot.pm

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl 5 itself.
