package Padre::Document::CSS;

use 5.008;
use strict;
use warnings;
use Carp            ();
use Padre::Document ();

our $VERSION = '0.22';
our @ISA     = 'Padre::Document';

sub comment_lines_str { return '//' }

sub get_help_provider {
	require Padre::Plugin::CSS::Help;
	return Padre::Plugin::CSS::Help->new;
}

sub find_help_topic {
	my ($self) = @_;

	# TODO code copied from Padre::Wx::Dialog::HelpSearch::find_help_topic
	# eliminate duplication!
	my $editor = $self->editor;
	my $pos    = $editor->GetCurrentPos;

	# The selected/under the cursor word is a help topic
	my $topic = $editor->GetSelectedText;
	if ( not $topic ) {
		$topic = $editor->GetTextRange(
			$editor->WordStartPosition( $pos, 1 ),
			$editor->WordEndPosition( $pos, 1 )
		);
	}

	warn "Topic '$topic'";
	return if not $topic;
	$topic =~ s/://;
	
	return $topic;
}


1;
