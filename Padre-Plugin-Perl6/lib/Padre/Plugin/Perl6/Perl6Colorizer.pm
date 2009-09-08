package Padre::Plugin::Perl6::Perl6Colorizer;

use 5.010;
use strict;
use warnings;

use Padre::Wx ();

our $VERSION = '0.59';

# colorize timer to make sure that colorize tasks are scheduled properly...
my $COLORIZE_TIMER;
my $COLORIZE_TIMEOUT = 100; # wait n-millisecond before starting the Perl6 colorize task


our $colorizer;

# colorizes a Perl 6 document in a timer
# one at a time;
# now the user can choose between PGE and STD colorizers
# via the preferences

sub colorize {
	my $self = shift;

	my $doc    = Padre::Current->document;
	my $config = Padre::Plugin::Perl6::plugin_config();
	if ( $config->{p6_highlight} || $doc->{force_p6_highlight} ) {

		my $timer_id = Wx::NewId();
		my $main     = Padre->ide->wx->main;
		$COLORIZE_TIMER = Wx::Timer->new( $main, $timer_id );
		Wx::Event::EVT_TIMER(
			$main,
			$timer_id,
			sub {

				# temporary overlay using the parse tree given by parrot
				# Create a coloring task
				my $module = $colorizer eq 'STD'
					? 'Padre::Plugin::Perl6::Perl6StdColorizerTask'  # STD
					: 'Padre::Plugin::Perl6::Perl6PgeColorizerTask'; # PGE
				eval "use $module";
				my $task = $module->new(
					text     => $doc->text_with_one_nl,
					editor   => $doc->editor,
					document => $doc
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
}


1;

__END__

=head1 AUTHOR

Ahmad M. Zawawi C<< <ahmad.zawawi at gmail.com> >>

Gabor Szabo L<http://szabgab.com/>

=head1 COPYRIGHT AND LICENSE

Copyright 2008-2009 Padre Developers as in Perl6.pm

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl 5 itself.
