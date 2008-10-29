package Padre::Document::Pasm;

use 5.008;
use strict;
use warnings;
use Padre::Document ();
use Padre::Util     (); # Px::

our $VERSION = '0.14';
our @ISA     = 'Padre::Document';

# Naive way to parse and colourise pasm files
sub colourise {
	my ($self, $first) = @_;

	$self->remove_color;

	my $editor   = $self->editor;
	my $text     = $self->text_get;
	my @keywords = qw(substr save print branch new set end 
	                 sub abs gt lt eq shift get_params if 
	                 getstdin getstdout readline bsr inc 
	                 push dec mul pop ret sweepoff trace 
	                 restore ge le);
	my $keywords = join '|', sort {length $b <=> length $a} @keywords;

	my %regex_of = (
		PASM_KEYWORD  => qr/$keywords/,
		PASM_REGISTER => qr/\$?[ISPN]\d+/,
		PASM_LABEL    => qr/^\s*\w*:/m,
		PASM_STRING   => qr/(['"]).*\1/,
		PASM_COMMENT  => qr/#.*/,
	);
	foreach my $color (keys %regex_of) {
		while ($text =~ /$regex_of{$color}/g) {
			my $end    = pos($text);
			my $length = length($&);
			my $start  = $end - $length;
			no strict "refs";
			my $str = 'Px::' . $color;
			$editor->StartStyling($start, $str->());
			$editor->SetStyling($length,  $str->());
		}
	}
}

sub remove_color {
	my ($self) = @_;

	my $editor = $self->editor;
	# TODO this is strange, do we really need to do it with all?
	for my $i ( 1 .. 5 ) {
		$editor->StartStyling(0, $i);
		$editor->SetStyling($editor->GetLength, 0);
	}

	return;
}

1;
