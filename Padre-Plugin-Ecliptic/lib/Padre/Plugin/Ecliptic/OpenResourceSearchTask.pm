package Padre::Plugin::Ecliptic::OpenResourceSearchTask;

use strict;
use warnings;
use base 'Padre::Task';
use Scalar::Util    ();
use Padre::Constant ();

our $VERSION        = '0.15';
our $thread_running = 0;

# This is run in the main thread before being handed
# off to a worker (background) thread. The Wx GUI can be
# polled for information here.
# If you don't need it, just inherit this default no-op.
sub prepare {
	my $self = shift;

	# it is not running yet.
	$self->{broken} = 0;

	# assign a place in the work queue
	if ($thread_running) {

		# single thread instance at a time please. aborting...
		$self->{broken} = 1;
		return "break";
	}
	$thread_running = 1;
	return 1;
}

sub is_broken {
	my $self = shift;
	return $self->{broken};
}

# This is run in the main thread after the task is done.
# It can update the GUI and do cleanup.
# You don't have to implement this if you don't need it.
sub finish {
	my ($self, $main) = @_;

	# finished here
	$thread_running = 0;

	return 1;
}

# Task thread subroutine
sub run {
	my $self = shift;

	return 1;
}

1;

__END__

=head1 AUTHOR

Ahmad M. Zawawi C<< <ahmad.zawawi at gmail.com> >>

=head1 COPYRIGHT AND LICENSE

Copyright 2009 C<< <ahmad.zawawi at gmail.com> >>

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl 5 itself.