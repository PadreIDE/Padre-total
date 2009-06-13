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
	foreach my $env( keys( %{ $self->{nytprof_envars} }  ) ) {
		$nytprof_env_vars .= "$env=" . $self->{nytprof_envars}->{$env} . ":";
	}
	$nytprof_env_vars =~ s/\:$//;
	
	# doesn't work as expected
	# local $ENV{NYTPROF} = $nytprof_env_vars;
	# my @cmd = ( $self->{perl}, '-d:NYTProf', $self->{doc_path} );
	
#	$self->print( "Env: $nytprof_env_vars\n" );
	#$self->task_print( "\nEnv: $nytprof_env_vars\n" . join(' ', @cmd) . "\n\n" );
	my $cmd = "NYTPROF=$nytprof_env_vars; export NYTPROF; " . $self->{prof_settings}->{perl} . ' -d:NYTProf ' . $self->{prof_settings}->{doc_path};
	$self->task_print("$cmd\n\n");
	#system("NYTPROF=$nytprof_env_vars; " . join(' ', @cmd) );
	system($cmd);
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