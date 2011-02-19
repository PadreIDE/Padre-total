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
	my $path = shift;
	my $commit_msg = shift;
		
	$self->_reset_error;
	
	# handle any message text, save to a temp file and use that in the svn command line
	require File::Temp;
	my $msg_file = File::Temp->new();
	print $msg_file $commit_msg;
	my $msg_path = $msg_file->filename();
	$msg_path =~ s!\\!/!g; # escape literal \ for Windows users. see RT#54969 
		
	print "Path: $path\n";
	print "messge file: $msg_path\n";
	
	my( $stdout, $stderr ) = capture {
		system "svn commit --file $msg_path $path";
	};
	
	# remove the temp file
	undef $msg_file;
	if( -s $msg_path ) {
		warn "temp file not removed";
	}
	
	if( $stderr ne "" ) {
		# handle error
		print "Error: $stderr\n";
		$self->{error} = 1;
		$self->{error_msg} = $stderr;
		
		return 0;
	}
	
	$self->{msg} = $stdout;
	
	return 1;
	
}

sub svn_info {
	my $self = shift;
	my $path = shift;
	
	$self->_reset_error;
	
	print "Path: $path\n";
	my ($stdout, $stderr ) = capture {
		system "svn info $path";
	};
	
	#print "stdout: $stdout\n\nstderr: $stderr\n\n";
	
	if( defined $stderr && $stderr ne "") {
		# when the file is not versioned it gets returned as an error in stderr, however
		# we don't want to return a true error in this case.
		if( $stderr =~ m/Not a versioned resource/i or 
		    $stderr =~ m/is not a working copy/  ) {
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

