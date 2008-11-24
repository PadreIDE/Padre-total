package Padre::Plugin::ThreadTest;

use 5.008;
use strict;
use warnings;

our $VERSION = '0.18';

use base 'Padre::Plugin';

sub menu_plugins_simple {
	my $self = shift;
	return 'Thread Test' => [
		'Test' => sub { $self->schedule_tasks },
		# 'Another Menu Entry' => sub { $self->about },
		# 'A Sub-Menu...' => [
		#     'Sub-Menu Entry' => sub { $self->about },
		# ],
	];
}

sub schedule_tasks {
  require Padre::Plugin::ThreadTest::Task;
  foreach (1..30) {
    my $task = Padre::Plugin::ThreadTest::Task->new();
    $task->schedule();
  }
  return;
}

1;
