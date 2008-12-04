
package Padre::Task;
use strict;
use warnings;

our $VERSION = '0.20';

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

During all this time, the state of your task object is retained!
So anything you store in the task object while in the worker thread
is still there when C<finish> runs in the main thread. (Confer the
CAVEATS section below!)

=head1 INSTANCE METHODS

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


{ # scope for main thread data storage
	my %MainThreadData;

	# this will serialize the object and do some magic as it happens
	# This is an INTERNAL method and subject to change
	sub serialize {
		my $self = shift;

		# The idea is to store the actual class of the object
		# in the object itself for serialization. It's not as bad as
		# it sounds. It just requires two things from the subclasses:
		# - The subclasses cannot override "deserialize" and thus
		#   probably not "serialize" either. But that shouldn't be
		#   a huge deal as there are the "prepare" and "finish" hooks
		#   for the user.
		# - The subclasses must not use the "_process_class" slot
		#   of the object. (Ohh...)
 
		# save the real object class for deserialization 
		my $class = ref($self);
		if (exists $self->{_process_class}) {
			require Carp;
			Carp::croak("The '_process_class' slot in a Padre::Task"
			            . " object is reserved for usage by Padre::Task");
		}

		$self->{_process_class} = $class;

		my $save_main_thread_data = (threads->tid() == 0 and exists $self->{main_thread_only});
		if ($save_main_thread_data) {
			my $id = "$self";
			$id .= '_' while exists $MainThreadData{$id};
			$MainThreadData{$id} = $self->{main_thread_only};
			$self->{_main_thread_data_id} = $id;
			delete $self->{main_thread_only};
		}

		# remove pesky dependency by explicitly
		# blessing into Padre::Task
		bless $self => 'Padre::Task';

		my $ret = $self->SUPER::serialize(@_);

		# cleanup
		delete $self->{_process_class};
		if ($save_main_thread_data) {
			$self->{main_thread_only} = $MainThreadData{$self->{_main_thread_data_id}};
			delete $self->{_main_thread_data_id};
		}
		bless $self => $class;

		return $ret;
	}

	# this will deserialize the object and do some magic as it happens
	# This is an INTERNAL method and subject to change
	sub deserialize {
		my $class = shift;

		my $padretask = Padre::Task->SUPER::deserialize(@_);
		my $userclass = $padretask->{_process_class};
		delete $padretask->{_process_class};

		no strict 'refs';
		my $ref = \%{"${userclass}::"};
		use strict 'refs';
		my $loaded = exists $ref->{"ISA"};
		if (!$loaded and !eval "require $userclass;") {
			require Carp;
			if ($@) {
				Carp::croak("Failed to load Padre::Task subclass '$userclass': $@");
			} else {
				Carp::croak("Failed to load Padre::Task subclass '$userclass': It did not return a true value.");
			}
		}

		# restore the main-thread-only data in the task
		if (threads->tid() == 0 and exists $padretask->{_main_thread_data_id}) {
			my $id = $padretask->{_main_thread_data_id};
			$padretask->{main_thread_only} = $MainThreadData{$id};
			delete $padretask->{_main_thread_data_id};
			delete $MainThreadData{$id};
		}

		my $obj = bless $padretask => $userclass;
		return $obj;
	}

} # end scope of main thread data storage


=head1 CLASS METHODS

=head2 subclass

As a convenience for the authors of C<Padre::Task> subclasses, the
C<subclass> method will create a subclass on the fly. For anything
slightly more complicated, you should probably prefer ordinary
subclassing. This works remotely similar to the subclass method of
Module::Build. It generates the subclass from the specified parameters
and returns the class name for convenience. Here is an example:

  my $subclass = Padre::Task->subclass(
      class => 'Padre::Task::Foo',
      methods => {
          run => sub {
              my $self = shift;
              print "Running in a worker thread.\n";
              print "Main thread says: '$self->{msg}'\n";
              $self->{answer} = 'Blah!';
          },
          finish => sub {
              my $self = shift;
              print "Running in the main thread.\n";
              print "Worker thread says: '$self->{answer}'\n";
          },
      },
  );
  
  my $obj = $subclass->new( msg => 'Hey there!' );
  $obj->schedule();

When this is run, it'll print (after being scheduled for
execution):

  Running in a worker thread.
  Main thread says: Hey there!
  Running in the main thread.
  Worker thread says: Blah!

C<subclass> takes the following parameters:

=over 2

=item class

The name of the class to create. Typically something like
C<Padre::Task::Yourname>. This is a required parameter.

=item code

An arbitrary piece of code (as a string) that will
be executed in the new package after loading strictures
and warnings and setting up the inheritance from
C<Padre::Task>. Use this to load additional modules.

=item methods

A reference to a hash containing method names as keys and
code references as values. The code references will be
installed as the methods in the new class.

=back

I<Note:> If the package you're trying to instantiate via
C<subclass> already exists, C<subclass> simply returns
the subclass name as if the subclass was freshly created.
This is on purpose so you can safely call C<subclass>
repeatedly without having to worry about the subclassing
really being a compile-time action.

=cut

sub subclass {
	my $proto = shift;
	my $class = ref($proto)||$proto;
	
	my %opts = @_;
	my $methods = $opts{methods} || {};
	my $targetclass = $opts{class};
	if (not defined $targetclass or $targetclass !~ /^[\w:]+$/) {
		croak("You must specify a valid class name!");
	}
	my $code = $opts{code} || '';

	return $targetclass if $class->_package_exists($targetclass);

	my $fullcode = <<HERE;
package $targetclass;
use strict; use warnings;
our \@ISA = qw($class);
$code
HERE
	eval $fullcode;
	if ($@) {
		croak("Could not generate subclass '$targetclass' of '$class' using"
		      . " the following code:\n---\n$fullcode\n---\nReason: $@"
		);
	}
	
	foreach my $method (keys %$methods) {
		my $sub = $methods->{$method};
		no strict 'refs';
		if (not defined *{"${targetclass}::$method"}{CODE}) {
			*{"${targetclass}::$method"} = $sub;
		}
	}

	return $targetclass;
}

sub _package_exists {
	my $self = shift;
	my $test_pkg = shift;
	my $pkg = \%::;
	while ( $test_pkg =~ /(.*?)::(.*)/m and exists $pkg->{$1."::"} ) {
		$pkg = *{$pkg->{$1."::"}}{HASH};
		$test_pkg = $2;
	}

	return exists $pkg->{$test_pkg."::"};
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
