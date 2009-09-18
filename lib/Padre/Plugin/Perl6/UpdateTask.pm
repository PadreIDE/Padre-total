package Padre::Plugin::Perl6::UpdateTask;

use 5.010;
use strict;
use warnings;
use Padre::Task ();
use Padre::Wx   ();

our $VERSION = '0.60';
our @ISA     = 'Padre::Task';

# set up a new event type
our $SAY_HELLO_EVENT : shared = Wx::NewEventType();

sub prepare {
	my $self = shift;

	$self->say( "Preparing " . $self->{release}->{name} );

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

sub say {
	my ( $self, $text ) = @_;
	$text .= "\n";
	print $text;
	$self->post_event( $SAY_HELLO_EVENT, $text );
}

sub on_progress {
	my ( $self, $percent, $text ) = @_;

	#XXX do some progress UI
}

sub run {
	my $self = shift;

	my $url = $self->{release}->{url};
	require URI;
	my $uri = URI->new($url);

	my $dest = 'c:/strawberry/';

	$self->say("Downloading $url...");
	require Net::HTTP;
	require HTTP::Status;
	my $s = Net::HTTP->new( Host => $uri->host ) || die $@;
	$s->write_request( GET => $uri->path . '?' . rand(10000), 'User-Agent' => "Mozilla/5.0" );
	my ( $code, $mess, %headers ) = $s->read_response_headers;
	$self->say("Received $mess ($code)\n");
	my $content_length = $headers{'Content-Length'};
	if ( $code != HTTP::Status->HTTP_OK ) {
		die "Could not download:\n\t$url,\n\terror code: $mess $code\n";
	}

	my $content    = '';
	my $downloaded = 0;
	while (1) {
		my $buf;
		my $n = $s->read_entity_body( $buf, 8096 );
		die "read failed: $!" unless defined $n;
		last unless $n;
		$downloaded += $n;
		my $percent = $downloaded / $content_length * 100.0;
		my $info    = sprintf(
			"Downloaded %d/%d bytes (%2.1f)\n",
			$downloaded, $content_length, $percent
		);
		$self->on_progress( $percent, $info );
		$content .= $buf;
	}

	$self->say( sprintf( "Writing zip file (size: %d bytes)", length $content ) );
	require File::Temp;
	my $zipFile = File::Temp->new( SUFFIX => '-six.zip', CLEANUP => 0 );
	binmode( $zipFile, ":raw" );
	print $zipFile $content;
	my $zipName = $zipFile->filename;
	close $zipFile or die "Cannot close temporary file" . $zipName . "\n";

	$self->say("Unzipping $zipName into $dest");
	require Archive::Zip;
	my $zip    = Archive::Zip->new();
	my $status = $zip->read($zipName);
	die "Read of $zipName failed\n" if $status != Archive::Zip->AZ_OK;

	$zip->extractTree( '', $dest );

	$self->say("Finished upgrade in %d");

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
