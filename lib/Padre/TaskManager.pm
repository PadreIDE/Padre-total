
package Padre::TaskManager;
use strict;
use warnings;

use threads;
use threads::shared; # according to Wx docs, this MUST be loaded before Wx, so this also happens in the script
use Thread::Queue;

require Padre;
use Padre::Task;
use Padre::Wx;
use Wx::Event qw(EVT_COMMAND EVT_CLOSE);

our $TASK_DONE_EVENT : shared = Wx::NewEventType;
our $REAP_TIMER;
our $SINGLETON;

#
# This IRC log is the only documentation for the time being. With a big TODO! FIXME!
#
#<tsee> - There's a pool of N worker threads which can either be started at launch time or when the first background task is scheduled. (This will need some more thought)
#<tsee> - Now, in order to create background tasks, you set up a "Padre::Task" subclass.
#<tsee> - It needs to implement at least the run() method which will be run in a worker thread.
#<tsee> - It can additionally implement prepare() and finish() which will be run in the main thread before and after delegation to the worker.
#<tsee> - Then, to actually use that, I added a simple hook to the My.pm plugin. (Plugins->My Plugin->test). There, I create new objects of the Padre::Task subclass "Padre::Plugin::My::Task".
#<tsee> - Set some data for sending to the worker thread with the object and call $taskobject->schedule().
#<tsee> - It will be sent to the Padre::TaskManager which will add it to a queue of jobs to be run.
#<tsee> (In fact, it also sets up the worker threads only on demand right now. Depending on the number of those, this can be a bit of a delay. Remember this is testing code)
#<tsee> The queue can only deal with simple data, so the task is serialized before being queued.
#<tsee> And deserialized in the worker.
#<tsee> - When a worker thread is idle, it checks the queue to see whether there is any work to do. Since for good measure, I submitted fifty jobs in the test, there'll be plenty.
#<tsee> - the worker runs $taskobj->run().
#<tsee> - When that's done, it serializes the object and creates a Wx event handler.
#<tsee> - In the Wx event handler in the main thread, the object it reconstructed once again and $taskobj->finish() is called.
#<tsee> - This hook can be used to actually implement any changes to the GUI.
#<tsee> - In this example case, we just grab the current document and add some text to the end.
#<tsee> - Which is just the time between scheduling of the job (which, by the way, sleeps for a second) and the time finish() is actually executed.
#<tsee> - Since there's a couple of worker threads churning away at the same time, this should happen in bunches.
#<tsee> - The editor stays responsive all the time.
#<tsee> *at all times
#
#<tsee> Threads make me weep.
#<tsee> There's tons of stuff left to do.
#<tsee> The least of which is the total lack of docs.
#<tsee> When a task kills a thread, it's respawned the next time any jobs a scheduled, for example.
#<tsee> When's the right time to start workers? Certainly the first idea is to do this only when jobs are submitted, BUT: How many do you spawn at a time? AND: If you spawn them late, they'll need more memory!
#<tsee> Using events, IIRC it's possible for worker threads to interact with the GUI in the main thread. How? And how safe is this?
#<tsee> Essentially, I'm doing that for the finish call.
#<tsee> I *think*.
#<tsee> What's the performance?
#<tsee> What happens if you pass a lot of data around -- will the serialization kill us?
#<tsee> etc.
#<tsee> Oh, and a biggie: What happens if the CPU can't run stuff fast enough so jobs queue up a lot?
#<tsee> I guess the queue should simply block the main thread at some point.
#<tsee> But then, tasks can't be finish()ed either.
#<tsee> Okay, I'll stop for now. This is enough to keep you poor man busy reading for a while.
#<tsee> Oh, and the cleanup routine needs work.
#<tsee> Timings: On my single-CPU four-year-old Athlon, a single (simple) background job has a total overhead of ~0.015s
#<tsee> With three worker threads, submitting three such jobs at once results in a total delay of ~0.019s for each job.
#<tsee> Remember this is a single-core machine.-
#<tsee> When submitting FIFTY at the same time, running time is between 0.064s and 0.078s.
#<tsee> The timing is only slightly worse with only one worker thread (0.068-0.084s), but that's not surprising since those jobs now don't block on anything and it's simply the the overhead of passing things around and doing so one job after another.
#<tsee> The timings improve similarly little when 20 worker threads are used, but memory overhead is ridicilous.

use Class::XSAccessor
	getters => {
		task_queue => 'task_queue',
	};


sub new {
	my $class = shift;
        
	return $SINGLETON if defined $SINGLETON;

	my $self = $SINGLETON = bless {
		min_no_workers => 1,
		max_no_workers => 3,
		@_,
		workers => [],
		task_queue => undef,
	} => $class;

	my $mw = Padre->ide->wx->main_window;

	EVT_COMMAND($mw, -1, $TASK_DONE_EVENT, \&on_task_done_event);
	EVT_CLOSE($mw, \&on_close);
 
	$self->{task_queue} = Thread::Queue->new();

	# Set up a regular action for reaping dead workers
	# and setting up new workers
	if (not defined $REAP_TIMER) {
		# explicit id necessary to distinguish from startup-timer of the main window
		my $timerid = Wx::NewId();
		$REAP_TIMER = Wx::Timer->new( $mw, $timerid );
		Wx::Event::EVT_TIMER(
			#$mw, $timerid, sub { $SINGLETON->reap(); },
			$mw, $timerid, sub { warn scalar($SINGLETON->workers); $SINGLETON->reap(); },
		);
		$REAP_TIMER->Start( 15000, Wx::wxTIMER_CONTINUOUS  ); # in ms
	}
	#$self->setup_workers();
	return $self;
}

sub setup_workers {
	my $self = shift;
	@_=(); # avoid "Scalars leaked"
	my $mw = Padre->ide->wx->main_window;

	# ensure minimum no. workers
	my $workers = $self->{workers};
	while (@$workers < $self->{min_no_workers}) {
		$self->_make_worker_thread($mw);
	}

	# add workers to satisfy demand
	my $jobs_pending = $self->task_queue->pending();
	if (@$workers < $self->{max_no_workers} and $jobs_pending > 2*@$workers) {
		my $target = int($jobs_pending/2);
		$target = $self->{max_no_workers} if $target > $self->{max_no_workers};
		$self->_make_worker_thread($mw) for 1..($target-@$workers);
	}

	return 1;
}

sub _make_worker_thread {
	my $self = shift;
	my $mw = shift;
	@_=();
	push @{$self->{workers}}, threads->create({'exit' => 'thread_only'}, \&worker_loop, $mw, $self);
}

# join all dead threads and remove them from the list of threads in 
# the list of workers
sub reap {
	my $self = shift;
	@_=(); # avoid "Scalars leaked"
	my $workers = $self->{workers};

	my @active_or_waiting;
	warn "--".scalar (@$workers);

	foreach my $thread (@$workers) {
		if ($thread->is_joinable()) {
			my $tmp = $thread->join();
		}
		else {
			push @active_or_waiting, $thread;
		}
	}
	$self->{workers} = \@active_or_waiting;
	warn "--".scalar (@active_or_waiting);

	# kill the no. of workers that aren't needed
	my $n_threads_to_kill =  @active_or_waiting - $self->{max_no_workers};
	$n_threads_to_kill = 0 if $n_threads_to_kill < 0;
	my $jobs_pending = $self->task_queue->pending();

	# slowly reduce the no. workers to the minimum
	$n_threads_to_kill++
	  if @active_or_waiting-$n_threads_to_kill > $self->{min_no_workers}
	  and $jobs_pending == 0;
	
	if ($n_threads_to_kill) {
		# my $target_n_threads = @active_or_waiting - $n_threads_to_kill;
		my $queue = $self->task_queue;
		$queue->insert( 0, ("STOP") x $n_threads_to_kill )
		  unless $queue->pending() and not ref($queue->peek(0));

		# We don't actually need to wait for the soon-to-be-joinable threads
		# since reap should be called regularly.
		#while (threads->list(threads::running) >= $target_n_threads) {
		#  $_->join for threads->list(threads::joinable);
		#}
	}

	$self->setup_workers();

	return 1;
}

sub schedule {
	my $self = shift;
	my $process = shift;
	if (not ref($process) or not $process->isa("Padre::Task")) {
		die "Invalid task scheduled!"; # TODO: grace
	}

	# cleanup old threads and refill the pool
	$self->reap();

	$process->prepare();

	my $string;
	$process->serialize(\$string);
	$self->task_queue->enqueue( [ref($process), $string] );

	return 1;
}

sub cleanup {
	my $self = shift;

	# the nice way:
	my @workers = $self->workers;
	$self->task_queue->insert( 0, ("STOP") x scalar(@workers) );
	while (threads->list(threads::running) >= 1) {
		$_->join for threads->list(threads::joinable);
	}
	$_->join for threads->list(threads::joinable);

	# didn't work the nice way?
	while (threads->list(threads::running) >= 1) {
		$_->detach(), $_->kill() for threads->list(threads::running);
	}

	return 1;
}

###################
# Accessors

sub workers {
	my $self = shift;
	return @{$self->{workers}};
}

###################
# Event Handlers

sub on_close {
	my ($mw, $event) = @_; @_ = (); # hack to avoid "Scalars leaked"

	# TODO/FIXME:
	# This should somehow get at the specific TaskManager object
	# instead of going through the Padre globals!
	Padre->ide->{task_manager}->cleanup();

	# TODO: understand cargo cult
	$event->Skip(1);
}

sub on_task_done_event {
	my ($mw, $event) = @_; @_ = (); # hack to avoid "Scalars leaked"
	my $frozen = $event->GetData;
	my $process = Padre::TaskManager->thaw_process($frozen);

	$process->finish($mw);
	return();
}

##########################
# Worker thread main loop

sub worker_loop {
	my ($mw, $taskmanager) = @_;  @_ = (); # hack to avoid "Scalars leaked"
	my $queue = $taskmanager->task_queue;
	require Storable;

	#warn threads->tid() . " -- Hi, I'm a thread.";

	while (my $task = $queue->dequeue ) {

		#warn threads->tid() . " -- got task.";

		#warn("THREAD TERMINATING"), return 1 if not ref($task) eq 'ARRAY';
		return 1 if not ref($task) eq 'ARRAY';

		my $class = $task->[0];

		# GET THE PROCESS
		my $okay = eval "require $class";
		if (!$okay or $@) {
			warn "Could not load class $class for running background task, skipping. This is a severe error.";
			next;
		}
                my $string = $task->[1];
		my $process = $class->deserialize( \$string );
		
		# RUN
		$process->run();

		# FREEZE THE PROCESS AND PASS IT BACK
		my $thread_event = Wx::PlThreadEvent->new(-1, $TASK_DONE_EVENT, Padre::TaskManager->freeze_process($process) );
		Wx::PostEvent($mw, $thread_event);

		#warn threads->tid() . " -- done with task.";
	}
}


################################################################
# Utility functions for serializing processes with their classes

sub freeze_process {
	my $selfclass = shift;
	my $obj = shift;
	my $string;
	$obj->serialize(\$string);
	my $stuff = [ref($obj), $string];
	return Storable::freeze($stuff);
}

sub thaw_process {
	my $selfclass = shift;
	my $string = shift;
	my $stuff = Storable::thaw($string);
	my $class = $stuff->[0];

	my $okay = eval "require $class";
	if (!$okay or $@) {
		warn "Could not load Padre::Task subclass $class. This is a severe error.";
		return();
	}
	return $class->deserialize( \$stuff->[1] );
}

1;


# Copyright 2008 Gabor Szabo.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.
