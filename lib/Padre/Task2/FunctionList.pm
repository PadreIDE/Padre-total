package Padre::Task2::FunctionList;

# Function list refresh task, done mainly as a full-feature proof of concept.

use 5.008005;
use strict;
use warnings;
use Padre::Task2   ();
use Padre::Current ();

our $VERSION = '0.62';
our @ISA     = 'Padre::Task2';
	




######################################################################
# Padre::Task2 API

sub run {
	my $self  = shift;

	# Load the document class
	SCOPE: {
		local $@;
		eval "require $self->{class};";
		return if $@;
	}
 
	# Get the function list
	my @functions = $self->{class}->find_functions( $self->{text} );
	if ( $self->{order} eq 'alphabetical' ) {
		# Alphabetical (aka 'abc')
		@functions = sort { lc($a) cmp lc($b) } @functions;
	} elsif ( $self->{order} eq 'alphabetical_private_last' ) {
		# ~ comes after \w
		tr/_/~/ foreach @functions;
		@functions = sort { lc($a) cmp lc($b) } @functions;
		tr/~/_/ foreach @functions;
	}

	$self->{list} = \@functions;
	return 1;
}

sub finish {
	my $self = shift;
	my $list = $self->{list} or return;
	my $wx   = Padre::Current->main->functions; # HACK: Terribly naive
	$wx->set( $list );
	$wx->render;
	return 1;
}

1;
