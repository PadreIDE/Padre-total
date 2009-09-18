package Padre::Plugin::Perl6::UpgradeTask;

use 5.008;
use strict;
use warnings;
use Padre::Task ();
use Padre::Wx   ();

our $VERSION = '0.46';
our @ISA     = 'Padre::Task';

# set up a new event type
our $SAY_HELLO_EVENT : shared = Wx::NewEventType();

sub prepare {

	# Set up the event handler
	Wx::Event::EVT_COMMAND(
		Padre->ide->wx->main,
		-1,
		$SAY_HELLO_EVENT,
		\&on_say_hello,
	);

	return;
}

# The event handler
sub on_say_hello {
	my ( $main, $event ) = @_;
	@_ = (); # hack to avoid "Scalars leaked"

	# Write a message to the beginning of the document
	my $editor = $main->current->editor;
	return if not defined $editor;
	$editor->InsertText( 0, $event->GetData );
}

sub run {
	my $self = shift;

	# post two events for fun
	$self->post_event( $SAY_HELLO_EVENT, "Hello from thread!\n" );
	sleep 1;
	$self->post_event( $SAY_HELLO_EVENT, "Hello again!\n" );

	return 1;
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