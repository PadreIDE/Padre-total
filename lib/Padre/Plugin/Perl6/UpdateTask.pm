package Padre::Plugin::Perl6::UpdateTask;

use 5.010;
use strict;
use warnings;
use Padre::Task    ();
use Padre::Wx      ();
use File::Copy     ();
use File::Spec     ();
use File::Basename ();
our $VERSION = '0.60';
our @ISA     = 'Padre::Task';

# set up new event types
our $PROGRESS_EVENT : shared = Wx::NewEventType();

my $strawberry_dir = 'c:/strawberry/';
my $six_dir        = 'c:/strawberry/six';

sub prepare {
	my $self = shift;

	# validate parameters...
	die "no release paramater"  if not $self->{release};
	die "no progress parameter" if not $self->{progress};

	$self->task_print( "Preparing " . $self->{release}->{name} . "\n" );

	# Set up event handlers
	Wx::Event::EVT_COMMAND(
		Padre->ide->wx->main,
		-1,
		$PROGRESS_EVENT,
		\&on_progress,
	);


	return;
}

#
# The PROGRESS_EVENT event handler
#
sub on_progress {
	my ( $main, $event ) = @_;
	@_ = (); # hack to avoid "Scalars leaked"

	use Data::Dumper; print Dumper($event);

	#my ($percent, $progress) = @{$event->GetData};
	#$progress->SetValue( $percent );
}

#
# Downloads Six distro and provides progress information
#
sub download_six {
	my $self = shift;

	my $url = $self->{release}->{url};
	require URI;
	my $uri = URI->new($url);

	$self->task_print("Downloading $url...\n");

	require Net::HTTP;
	require HTTP::Status;
	my $s = Net::HTTP->new( Host => $uri->host ) || die $@;
	$s->write_request( GET => $uri->path . '?' . rand, 'User-Agent' => "Mozilla/5.0" );
	my ( $code, $mess, %headers ) = $s->read_response_headers;
	$self->task_print("Received $mess ($code)\n");
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

		#Update the progress bar
		#		my %data : shared = (
		#			downloaded => int($downloaded / $content_length * 100),
		#			progress   => $self->{progress},
		#		);
		$self->post_event( $PROGRESS_EVENT, $downloaded );

		#Added downloaded stuff...
		$content .= $buf;
	}

	return $content;
}

#
# Renaming the old six directory (just in case)
# XXX-we should restore that in case of installation failure
#
sub backup_six {
	my $self = shift;

	my ( $sec, $min, $hour, $day, $mon, $year ) = localtime;
	my $timestamp = sprintf(
		"%4d%02d%02d-%02d%02d%02d",
		$year + 1900, $mon + 1, $day, $hour, $min, $sec
	);
	if ( -d $six_dir ) {
		my $new_six_dir = $six_dir . "_" . $timestamp;
		$self->task_print("Backing up old six directory to $new_six_dir\n");
		File::Copy::move( $six_dir, $new_six_dir )
			or die "Cannot rename $six_dir to $new_six_dir\n";
	}
}

#
# unzip six zip file to the destination folder
#
sub unzip_six {
	my ( $self, $content ) = @_;

	# Write the zip file to a temporary file
	$self->task_print( sprintf( "Writing zip file (size: %d bytes)\n", length $content ) );
	require File::Temp;
	my $zip_temp = File::Temp->new( SUFFIX => '-six.zip', CLEANUP => 0 );
	binmode( $zip_temp, ":raw" );
	print $zip_temp $content;
	my $zip_name = $zip_temp->filename;
	close $zip_temp or die "Cannot close temporary file" . $zip_name . "\n";

	# and then unzip it to destination
	$self->task_print("Unzipping $zip_name into $six_dir\n");
	require Archive::Zip;
	my $zip    = Archive::Zip->new();
	my $status = $zip->read($zip_name);
	die "Read of $zip_name failed\n" if $status != Archive::Zip->AZ_OK;
	$zip->extractTree( '', $strawberry_dir );
}

#
# In here, we're running in the background :)
#
sub run {
	my $self = shift;

	# start the clock
	my $clock = time;

	my $content = $self->download_six;
	$self->backup_six;
	$self->unzip_six($content);

	# We're done here...
	$self->task_print( sprintf( "Finished installation in %d sec(s)", time - $clock ) );

	return 1;
}

#
# This is run in the main thread after the task is done.
# It can update the GUI and do cleanup.
#
sub finish {
	my ( $self, $main ) = @_;

	print "Finished!\n";

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
