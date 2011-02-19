package Padre::Plugin::SVN::Commands;

use strict;
use warnings;

#use Data::Dumper;
use Capture::Tiny 'capture';

sub new {
	my $class = shift;
	
	my $self = {};
	
	$self->{error} = 0;
	$self->{error_msg} = "";
	$self->{msg} = "";
	
	
	
	bless $self, $class;
	
	# check if we have svn installed
	if( ! $self->have_svn() ) {
		$self->{error} = 0;
		$self->{error_msg} = 'The SVN commandline tools do not appear to be installed on your system.';
		
	}
	else {
		#print "SVN is installed\n";
	}
	
	return $self;
}



sub have_svn {
	my $self = shift;
	
	# simple check to see if we have svn commandline tools installed
	my ($stdout, $stderr);
	($stdout, $stderr) = capture {
		system('svn help');
	};
	
	
	#print Dump($stdout);
	if( $stdout =~ m/useage:/ ) {
		return 1;
	}
	else {
		return 0;
	}
}


sub svn_commit {
	my $self = shift;
	my $file = shift;
	
	
	
}

sub svn_info {
	my $self = shift;
	my $path = shift;
	
	$self->_reset_error;
	

	#my $cmd  = qx{ svn info $path };
	#print "command: $cmd\n";
	#return;
	my ($stdout, $stderr ) = capture {
		system "svn info $path";
	};
	
	#print "stdout: $stdout\n\nstderr: $stderr\n\n";
	
	if( defined $stderr && $stderr ne "") {
		# when the file is not versioned it gets returned as an error in stderr, however
		# we don't want to return a true error in this case.
		if( $stderr =~ m/Not a versioned resource/ ) {
			$self->{msg} = $stderr;
			return 1;
		}
		
		$self->{error} = 1;
		$self->{err_msg} = $stderr;
		return 0;
	}
	
	#print "svn_info: $stdout\n";
	$self->{msg} = $stdout;
	
	return 1;
	
}

sub _reset_error {
	my $self = shift;
	$self->{msg} = "";
	$self->{error} = 0;
	$self->{error_msg} = "";
}


sub error {
	my $self = shift;
	
	return $self->{error};
}

sub error_msg {
	my $self = shift;
	return $self->{error_msg};
}

sub msg {
	return shift->{msg};
}

sub _check_exists {
	my $self = shift;
	my $path = shift;
	
}
1;

