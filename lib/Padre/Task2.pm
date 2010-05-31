package Padre::Task2;

use 5.008;
use strict;
use warnings;
use Storable       ();
use Scalar::Util   ();
use Padre::Current ();

our $VERSION = '0.59';

use Class::XSAccessor {
	constructor => 'new',
	getters     => {
		handle => 'handle',
	},
};

sub running {
	defined $_[0]->{handle};
}





######################################################################
# Task API - Based on Process.pm

# Send the task to the task manager to be executed
sub schedule {
	Padre::Current->ide->task2_manager->schedule(@_);
}

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





######################################################################
# Serialization - Based on Process::Serializable and Process::Storable

# my $string = $task->as_string;
sub as_string {
	Storable::nfreeze($_[0]);
}

# my $task = Class::Name->from_string($string);
sub from_string {
	my $class = shift;
	my $self  = Storable::thaw($_[0]);
	unless ( Scalar::Util::blessed($self) eq $class ) {
		# Because this is an internal API we can be brutally
		# unforgiving is we aren't use the right way.
		die("Task unexpectedly did not deserialize as a $class");
	}
	return $self;
}

1;

# Copyright 2008-2010 The Padre development team as listed in Padre.pm.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.
