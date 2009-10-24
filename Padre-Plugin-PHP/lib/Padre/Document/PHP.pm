package Padre::Document::PHP;

use 5.008;
use strict;
use warnings;
use Carp            ();
use Padre::Document ();

our $VERSION = '0.01';
our @ISA     = 'Padre::Document';

sub comment_lines_str { return '#' }

sub event_on_char {
	my ( $self, $editor, $event ) = @_;

	my $main   = Padre->ide->wx->main;
	my $config = Padre->ide->config;

	$editor->Freeze;

	$self->autocomplete_matching_char($editor,$event,
			34  => 34,  # " "
			39  => 39,  # ' '
			40  => 41,  # ( )
			60  => 62,  # < >
			91  => 93,  # [ ]
			123 => 125, # { }
		);

	$editor->Thaw;

	$main->on_autocompletion($event) if $config->autocomplete_always;

	return;
}

1;
