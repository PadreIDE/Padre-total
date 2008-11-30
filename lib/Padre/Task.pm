
package Padre::Task;
use strict;
use warnings;

require Padre;

use base qw{Process::Storable Process};

=pod

=head1 NAME

Padre::Task - Padre Background Task API

=head1 SYNOPSIS

Create a subclass of Padre::Task which implements your background
task:

  package Padre::Task::Foo;
  
  use base 'Padre::Task';
  
  # This is run in the main thread before being handed
  # off to a worker (background) thread. The Wx GUI can be
  # polled for information here.
  # If you don't need it, just inherit this default no-op.
  sub prepare {
          my $self = shift;
          return 1;
  }

  # This is run in a worker thread and make take a long-ish
  # time to finish. It must not touch the GUI, except through
  # Wx events. TODO: explain how this works
  sub run {
          my $self = shift;
          # Do something that takes a long time!
          return 1;
  }

  # This is run in the main thread after the task is done.
  # It can update the GUI and do cleanup.
  # You don't have to implement this if you don't need it.
  sub finish {
          my $self = shift;
          my $mainwindow = shift;
          # cleanup!
          return 1;
  }
  
  1;

From your code, you can then use this new background task class as
follows. (C<new> and C<schedule> are inherited.)

  require Padre::Task::Foo;
  my $task = Padre::Task::Foo->new(some => 'data');
  $task->schedule(); # hand off to the task manager

=head1 DESCRIPTION

This is the base class of all background operations in Padre. The SYNOPSIS
explains the basic usage, but in a nutshell, you create a subclass, implement
your own custom C<run> method, create a new instance, and call C<schedule>
on it to run it in a worker thread. When the scheduler has a free worker
thread for your task, the following steps happen:

=over 2

=item The scheduler calls C<prepare> on your object.

=item The scheduler serializes your object with C<Storable>.

=item Your object is handed to the worker thread.

=item The thread deserializes the task object and calls C<run()> on it.

=item After C<run()> is done, the thread serializes the object again
and hands it back to the main thread.

=item In the main thread, the scheduler calls C<finish> on your
object with the Padre main window object as argument for cleanup.

=back

=head1 METHODS

=cut

=head2 schedule

C<Padre::Task> implements the scheduling logic for your
subclass. Simply call the C<schedule> method to have your task
processed by the task manager.

Calling this multiple times will submit multiple jobs.

=cut

sub schedule {
	my $self = shift;
	Padre->ide->task_manager->schedule($self);
}

=head2 new

C<Padre::Task> provides a basic constructor for you to
inherit. It simply stores all provided data in the internal
hash reference.

=cut

sub new {
	my $class = shift;
	bless { @_ }, $class;
}

=head2 run

This is the method that'll be called in the worker thread.
You must implement this in your subclass.

You must not interact with the Wx GUI directly from the
worker thread. You may use Wx thread events only.
TODO: Experiment with this and document it.

=cut

sub run {
	my $self = shift;
	warn "This is Padre::Task->run(); Somebody didn't implement his background task's run() method!";
	return 1;
}

=head2 prepare

In case you need to set up things in the main thread,
you can implement a C<prepare> method which will be called
right before serialization for transfer to the assigned
worker thread.

You do not have to implement this method in the subclass.

=cut

sub prepare {
	my $self = shift;
	return 1;
}

=head2 finish

Quite likely, you need to actually use the results of your
background task somehow. Since you cannot directly
communicate with the Wx GUI from the worker thread,
this method is called from the main thread after the
task object has been transferred back to the main thread.

The first and only argument to C<finish> is the Padre
main window object.

You do not have to implement this method in the subclass.

=cut

sub finish {
	my $self = shift;
	return 1;
}

1;

__END__

=head1 NOTES AND CAVEATS

Since the task objects are transferred to the worker threads via
C<Storable::freeze()> / C<Storable::thaw()>, you cannot put any data
into the objects that cannot be serialized by C<Storable>. I<To the best
of my knowledge>, that includes filehandles and code references.

=head1 SEE ALSO

The management of worker threads is implemented in the L<Padre::TaskManager>
class.

C<Padre::Task> inherits from L<Process> and L<Process::Storable>.

The transfer of the objects to and from the worker threads is implemented
with L<Storable>.

=head1 AUTHOR

Steffen Mueller C<smueller@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright 2008 Gabor Szabo.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl 5 itself.

=cut

# Copyright 2008 Gabor Szabo.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.
