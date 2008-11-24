
package Padre::Plugin::ThreadTest::Task;
use strict;
use warnings;

require Padre;

use base qw{Padre::Task};

sub run {
	my $self = shift;
        warn "in task";
        use Time::HiRes qw/sleep/;
        sleep(0.3);
#	warn "This is Padre::Task->run(); Somebody didn't implement his background task's run() method!";
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

