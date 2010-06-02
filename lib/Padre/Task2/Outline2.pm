package Padre::Task2::Outline2;

# Function list refresh task, done mainly as a full-feature proof of concept.

use 5.008005;
use strict;
use warnings;
use Padre::Task2   ();

our $VERSION = '0.62';
our @ISA     = 'Padre::Task2';





######################################################################
# Padre::Task2 API

sub run {
	my $self  = shift;

	# Pull the text off the task so we won't need to serialize
	# it back up to the parent Wx thread at the end of the task.
	my $text = delete $self->{text};

	# Generate the outline
	$self->{data} = $self->find( $text );

	return 1;
}

sub finish {
	my $self  = shift;
	my $data  = $self->{data} or return;
	my $owner = $self->owner  or return;
	if ( $owner->can('task_response') ) {
		$owner->task_response($self);
	}
	return 1;
}





######################################################################
# Padre::Task2::FunctionList API

# Show an empty function list by default
sub find {
	return [];
}

1;
