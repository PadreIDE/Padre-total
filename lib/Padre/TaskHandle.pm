package Padre::TaskHandle;

use strict;
use warnings;
use threads;
use threads::shared;
use Thread::Queue 2.11;

our $VERSION  = '0.58';
our $SEQUENCE = 0;





######################################################################
# Constructor and Accessors

sub new {
	my $class = shift;
	my $self  = bless {
		id          => ++$SEQUENCE,
		task_object => shift,
	}, $class;
	return $self;
}

sub id {
	$_[0]->{id};
}

sub task_object {
	$_[0]->{task_object};
}

sub task_class {
	$_[0]->{task_class};
}

sub task_string {
	$_[0]->{task_string};
}





######################################################################
# Message Passing

1;
