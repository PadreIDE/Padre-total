package Padre::Plugin::Parrot::HL;
use strict;
use warnings;

use Padre::Wx ();

our $VERSION = '0.26';

# colorize timer to make sure that colorize tasks are scheduled properly...
my $COLORIZE_TIMER;
my $COLORIZE_TIMEOUT = 100; # wait n-millisecond before starting the colorize task

# copied from the Perl 6 plugin
sub colorize {
	my $self = shift;
	my @args = @_;

	my ( $pbc, $path ) = $self->pbc_path;

	#print "PP::HL: $self  $pbc  $path\n";

	my $doc      = Padre::Current->document;
	my $timer_id = Wx::NewId();
	my $main     = Padre->ide->wx->main;
	$COLORIZE_TIMER = Wx::Timer->new( $main, $timer_id );
	Wx::Event::EVT_TIMER(
		$main,
		$timer_id,
		sub {
			require Padre::Plugin::Parrot::ColorizeTask;
			my $task = Padre::Plugin::Parrot::ColorizeTask->new(
				text     => $doc->text_with_one_nl,
				editor   => $doc->editor,
				document => $doc,
				pbc      => $pbc,
				path     => $path,
			);

			# hand off to the task manager
			$task->schedule();

			# and let us schedule that it is running properly or not
			if ( $task->is_broken ) {

				# let us reschedule colorizing task to a later date..
				$COLORIZE_TIMER->Stop;
				$COLORIZE_TIMER->Start( $COLORIZE_TIMEOUT, Wx::wxTIMER_ONE_SHOT );
			}
		},
	);

	# let us reschedule colorizing task to a later date..
	$COLORIZE_TIMER->Stop;
	$COLORIZE_TIMER->Start( $COLORIZE_TIMEOUT, Wx::wxTIMER_ONE_SHOT );
}


1;

__END__

=head1 NAME

Padre::Plugin::Perl6 - Padre plugin for Perl 6

=head1 SYNOPSIS

After installation when you run Padre there should be a menu option Plugins/Perl 6.

=head1 AUTHOR

Gabor Szabo L<http://szabgab.com/>

Ahmad M. Zawawi C<< <ahmad.zawawi at gmail.com> >>

=head1 COPYRIGHT AND LICENSE

Copyright 2008-2009 Padre Developers as in Perl6.pm

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl 5 itself.