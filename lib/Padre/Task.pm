
package Padre::Task;
use strict;
use warnings;

require Padre;

use base qw{Process::Storable Process};

sub schedule {
	my $self = shift;
	Padre->ide->task_manager->schedule($self);
}

sub new {
	my $class = shift;
	bless { @_ }, $class;
}

sub run {
	my $self = shift;
	warn "This is Padre::Task->run(); Somebody didn't implement his background task's run() method!";
	return 1;
}

sub prepare {
	my $self = shift;
	return 1;
}

sub finish {
	my $self = shift;
	return 1;
}

1;

