package Padre::Task2::FunctionList;

# Function list refresh task, done mainly as a full-feature proof of concept.

use 5.008005;
use strict;
use warnings;
use Padre::Task2::View ();
use Padre::Current     ();

our $VERSION = '0.62';
our @ISA     = 'Padre::Task2::View';





######################################################################
# Padre::Task2 API

sub run {
	my $self  = shift;

	# Pull the text off the task so we won't need to serialize
	# it back up to the parent Wx thread at the end of the task.
	my $text = delete $self->{text};

	# Load the document class
	SCOPE: {
		local $@;
		eval "require $self->{class};";
		return if $@;
	}
 
	# Get the function list
	my @functions = $self->{class}->find_functions( $text );
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
	my $view = $self->view or return;
	my $list = $self->{list} or return;
	$view->set( $list );
	$view->render;
	return 1;
}

1;
