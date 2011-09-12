package Padre::Plugin::SVN::Info;

# Simple class to hold info details from svn info

use 5.008;
use strict;
use warnings;

use Data::Dumper;


sub new {
	my $class = shift;
	
	my $self =  {};
	$self->{info} = {};
	
	return bless $self, $class;
	
	
}

sub parse_info {
		my $self = shift;
		my $info = shift;  # string coming in?
		
		print "Parsing\n";
		
		#print "Info:: $info\n\n\n";

		$info =~ m/Path:\s(.*)$/m;
		#print "Found Path: $1\n";
		$self->{info}->{path} = $1;
		 
		 $info =~ m/Name:\s(.*)$/m;
		 #print "Found File Name: $1\n";
		 $self->{info}->{file_name} = $1;
		 
		 $info =~ m/URL:\s(.*)$/m;
		 #print "Found URL: $1\n";
		 $self->{info}->{URL} = $1;
		 
}



sub repo {
		my $self = shift;
		return $self->{info}->{URL};

}

sub path {
		my $self = shift;
		 return $self->{info}->{path};
}


1;