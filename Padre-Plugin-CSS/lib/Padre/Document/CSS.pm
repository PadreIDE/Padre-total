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
	
	# TODO: recognize tags with dash in the name: background-color
	# TODO: recognize values that include a number: 4px
	# TODO: recognize pseudo-class selectors:   :visited

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

	#warn "Topic '$topic'";
	return if not $topic;
	$topic =~ s/://;
	
	return lc $topic;
}


1;
