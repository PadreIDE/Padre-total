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

	# Pull the text off the task so we won't need to serialize
	# it back up to the parent Wx thread at the end of the task.
	my $text = delete $self->{text};

	# Get the function list
	my @functions = $self->find( $text );

	# Sort it appropriately
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
	my $self  = shift;
	my $list  = $self->{list} or return;
	my $owner = $self->owner  or return;
	$owner->set( $list );
	return 1;
}





######################################################################
# Padre::Task2::FunctionList API

# Show an empty function list by default
sub find {
	return ();
}

1;
