package Padre::Documents;

use 5.008;
use strict;
use warnings;

=head1 NAME

Padre::Documents

=head1 SYNOPSIS

Currently there are only class methods in this class.

=head1 METHODS

=cut

sub current {
	$_[0]->by_id( $_[0]->_notebook->GetSelection );
}

sub by_id {
	my $class   = shift;
	my $pageid  = shift;

	# TODO maybe report some error?
	return if not defined $pageid or $pageid =~ /\D/;

	if ( $pageid == -1 ) {
		# No page selected
		return;
	}

	return if $pageid >= $class->_notebook->GetPageCount;

	my $page = $class->_notebook->GetPage( $pageid );

	return $page->{Document};
}


sub _notebook {
	Padre->ide->wx->main_window->{notebook};
}

1;
