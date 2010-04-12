package Padre::Task2;

use 5.008;
use strict;
use warnings;

our $VERSION = '0.59';





##################################################
# Constructor and Accessors

sub new {
	my $class = shift;
	my $self  = bless { @_ }, $class;
	return $self;
}

sub handle {
	$_[0]->{handle};
}

sub running {
	defined $_[0]->{handle};
}





######################################################################
# Task API

# Called in the parent thread immediately before being passed
# to the worker thread. This method should compensate for
# potential time difference between when C<new> is original
# called, and when the Task is actually run.
# Returns true if the task should continue and be run.
# Returns false if the task is irrelevant and should be aborted.
sub prepare {
	return 1;
}

# Called in the worker thread, and should continue the main body
# of code that needs to run in the background.
# Variables saved to the object in the C<prepare> method will be
# available in the C<run> method.
sub run {
	return 1;
}

# Called in the parent thread immediately after the task has
# completed and been passed back to the parent.
# Variables saved to the object in the C<run> method will be
# available in the C<finish> method.
# The object may be destroyed at any time after this method
# has been completed.
sub finish {
	return 1;
}

1;
