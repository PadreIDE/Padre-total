package Padre::Documents;

use 5.008;
use strict;
use warnings;

### Only Class methods

sub from_selection {
	$_[0]->from_pageid( $_[0]->_notebook->GetSelection );
}

sub from_pageid {
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
