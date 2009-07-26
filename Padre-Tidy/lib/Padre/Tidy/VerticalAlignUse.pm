package Padre::Tiny::VerticalAlignUse;

use 5.008;
use strict;
use PPI::Transform          1.203 ();
use Padre::Tiny::VerticalAlignUse ();

our $VERSION = '0.01';

sub document {
	my $self     = shift;
	my $document = _INSTANCE(shift, 'PPI::Document') or return undef;

	# Filter for use lines
	my @children = grep {
		$_->isa('PPI::Statement::Include')
		and
		$_->type eq 'use'
		and
		$_->schild(2)
		and
		$_->schild(2)->isa('PPI::Token::Number')
			? (scalar($_->schildren) > 3)
			: (scalar($_->schildren) > 2)
	} $document->schildren;

	# Look for groups of them
	my @groups   = ();
	my @group    = ();
	my $lastline = -1;
	foreach my $use ( @children ) {
		my $line = $use->location->line;
		if ( $line > $lastline + 1 ) {
			if ( @group > 1 ) {
				# Complete the existing cluster
				push @groups, \@group;
			} else {
				# Discard the non-group
				@group = ();
			}
		}

		# Add to the existing (or new) group
		push @group, $use;
		$lastline = $line;
	}
	if ( @group > 1 ) {
		# Add the final group
		push @groups, \@group;
	}

	# Align each of the groups
	foreach my $group ( @groups ) {
		$self->_vertical_align_group( $group );
	}

	return 1;
}

sub _vertical_align_group {
	my $self = shift;

	
}

1;
