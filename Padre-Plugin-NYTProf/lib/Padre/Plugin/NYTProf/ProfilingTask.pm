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
	my $self = $class->SUPER::new(@_);
	
	$self->{doc_path} = Padre::Current->document->filename;
	$self->{temp_dir} = File::Temp::tempdir;
	$self->{perl} = Padre->perl_interpreter;
	$self->{nytprof_envars} = \%nytprof_envars;
	
	# write the output to what ever temp is
	$self->{nytprof_envars}->{file} = $self->{temp_dir} . '/nytprof.out';
	
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
	local $ENV{NYTPROF} = $nytprof_env_vars;
	my @cmd = ( $self->{perl}, '-d:NYTProf', $self->{doc_path} );
	
#	$self->print( "Env: $nytprof_env_vars\n" );
	$self->task_print( "\nEnv: $nytprof_env_vars\n" . join(' ', @cmd) . "\n\n" );
	
	system(@cmd);
	return 1;
}


sub finish {
	my $self = shift;

	print "\nFinished profiling...\n";
	
	return 1;
	
}


1;
__END__