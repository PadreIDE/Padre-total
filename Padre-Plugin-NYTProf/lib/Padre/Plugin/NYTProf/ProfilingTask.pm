package Padre::Plugin::NYTProf::ProfilingTask;

use strict;
use warnings;

our $VERSION = '0.01';


use base 'Padre::Task';


# we may want to set some default settings for NYTProf at some stage:
# keys should be relate to the environment vars NYTProf expects
my %nytprof_envars = (
		file	=> 'nytprof.out',
		);

sub new {
	
	my $class = shift;
	my $prof_settings = shift ;
	
	my $self = $class->SUPER::new(@_);
	
	
	
	$self->{prof_settings} = $prof_settings;
	

	print "Perl is: " . $self->{prof_settings}->{perl} ."\n";
	
	
	$self->{nytprof_envars} = \%nytprof_envars;
	
	# write the output to whatever temp is
	$self->{nytprof_envars}->{file} = $self->{prof_settings}->{report_file};
	
	bless( $self, $class );
	return $self;
	
}

sub run {
	my $self = shift;
	
	my $nytprof_env_vars = "";
	my $drive = "";
	foreach my $env( keys( %{ $self->{nytprof_envars} }  ) ) {
		# we can't use the full file path because the colon
		# in the file path is the same delimiter NYTProf uses
		# for NYTPROF environment variable.
		# not the best but:
		print "env: $env\n";
		if( ($env eq 'file') && ($^O eq 'MSWin32') ) {
			print "setting drive for win32\n";
			$self->{nytprof_envars}->{$env} =~ /(\w\:)(.*$)/;
			$drive = $1;
			$self->{nytprof_envars}->{$env} = $2;
		}
		$nytprof_env_vars .= "$env=" . $self->{nytprof_envars}->{$env} . ":";
	}
	$nytprof_env_vars =~ s/\:$//;
	
	# doesn't work as expected
	# local $ENV{NYTPROF} = $nytprof_env_vars;
	# my @cmd = ( $self->{perl}, '-d:NYTProf', $self->{doc_path} );
	
#	$self->print( "Env: $nytprof_env_vars\n" );
	#$self->task_print( "\nEnv: $nytprof_env_vars\n" . join(' ', @cmd) . "\n\n" );
	
	my $cmd = '';
	if( $^O eq "MSWin32" ) {
		print "Running on windows\n";
		$cmd = "$drive && set NYTPROF=$nytprof_env_vars && ";
	}
	elsif( $^O eq "darwin" ) {
		print "Running on Darwin\n";
		
		
	}
	elsif( $^O eq "linux" ) {
		print "running on linux\n";
		$cmd = "NYTPROF=$nytprof_env_vars; export NYTPROF; "; # . $self->{prof_settings}->{perl} . ' -d:NYTProf ' . $self->{prof_settings}->{doc_path};
	}
	
	# run the command if we can
	if( $cmd ne '' ) {
		# append the rest of the command here
		$cmd .= $self->{prof_settings}->{perl} . ' -d:NYTProf ' . $self->{prof_settings}->{doc_path};
		$self->task_print("$cmd\n\n");
		system($cmd);
	}
	else {
		print "Unable to determine your OS\n";
	}
	
	return 1;
}


sub finish {
	my $self = shift;
	# get main and write to the output.
	print "\nFinished profiling...\n";
	
	return 1;
	
}


1;
__END__
=head1 NAME

Padre::Plugin::NYTProf::ProfilingTask - Creates a Padre::Task to do the profiling in the background.

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

Creates and runs the profilng task against your scripts from within Padre.

This should be called from the plugin module.

=head1 DESCRIPTION

Called from the plugin module.


=head1 AUTHOR

Peter Lavender, C<< <peter.lavender at gmail.com> >>

=head1 BUGS

Plenty I'm sure, but since this doesn't even load anything I'm fairly safe.



=head1 SUPPORT

#padre on irc.perl.org


=head1 ACKNOWLEDGEMENTS

I'd like to acknowledge the support and patience of the #padre channel.

With nothing more than bravado and ignorance I pulled this together with the help of those in the #padre
channel answering all my clearly lack of reading questions.

=head1 SEE ALSO

L<Catalyst>, L<Padre>


=head1 COPYRIGHT & LICENSE

Copyright 2008-2009 The Padre development team as listed in Padre.pm.
all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

