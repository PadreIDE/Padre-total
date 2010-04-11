package Padre::Plugin::SQL::DBConnection;

use strict;
use warnings;

our $VERSION = '0.01';


use DBI;

# what DBD to use is dependant on the database we are connecting to


sub new {
	my $class = shift;
	my $connection = shift;
	
	my $self = {};
	bless $self, $class;
	$self->{err} = undef;
	$self->{errstr} = undef;
	
	$self->connect($connection);
	
	return $self;	
}


sub connect {
	my $self = shift;
	my $connection = shift;
	
	#check if we have an open connection
	if( $self->is_connected ) {
		$self->{dbh}->disconnect;
		
	}
	
	my $host = $connection->{dbhost};
	my $dbname = $connection->{dbname};
	my $instance = $connection->{dbinstance};
	my $port = $connection->{dbport};
	my $username =  $connection->{username};
	my $password = $connection->{password};
	# do the checks here
	
	print "in _get_connection_driver\nhost: $host,dbname: $dbname, instance: $instance, username:$username,port: $port\n";
	
	my $dbh;
	
	# postgres
	if( lc($connection->{dbtype}) eq 'postgres' ) {
		require DBD::Pg;
		$dbh = DBI->connect("dbi:Pg:dbname=$dbname;host=$host;port=$port", $username, $password );
	}
	
	
	if( lc($connection->{dbtype}) eq 'mysql' ) {
		require DBD::mysql;
		$dbh = DBI->connect("dbi:mysql:dbname=$dbname;host=$host;port=$port", $username, $password);
	}


	# check if any of the connections have an error
	if( $DBI::err ) {
		$self->{err} = $DBI::err;
		$self->{errstr} = $DBI::errstr;
		return;
	}
	
	$self->{dbh} = $dbh;

}

sub run_query {
	my $self = shift;
	my $query = shift;
	
	$self->{err} = undef;
	$self->{errstr}  = undef;
	
	# check we still have a connection to the database
	if( ! defined($query) || $query eq '' ) {
		$self->{err} = 1;
		$self->{errstr} = 'No query string passed in.';
		return;
	}
	
	# prepare the query
	my $sth = $self->{dbh}->prepare($query);	
	if( $sth->err ) {
		$self->{err} = $sth->err;
		$self->{errstr} = $sth->errstr;
		return;
	}
	
	#execute the query
	$sth->execute();
	if( $sth->err ) {
		$self->{err} = $sth->err;
		$self->{errstr} = $sth->errstr;
		return;
	}
	
	my @results;
	$results[0] = $sth->{NAME};
	$results[1] = $sth->fetchall_arrayref();
	
	$self->{results} = \@results;
	$sth->finish;
	
}

sub err {
	my $self = shift;
	return $self->{err};
}

sub errstr {
	my $self = shift;
	return $self->{errstr};
}

sub get_results {
	my $self = shift;
	return $self->{results};
}

sub disconnect {
	my $self = shift;
	if( defined( $self->{dbh} ) && $self->{dbh}->ping ) {
		
		$self->{dbh}->disconnect;
		$self->{dbh} = undef; # don't know about this
	}
	else {
		print "not connected... silently ignored\n";
	}
	
	
}

sub is_connected {
	my $self = shift;
	
	if( ! defined $self->{dbh} ) {
		return 0;
	}
	
	return $self->{dbh}->ping;
	
	
}

1;

# Copyright 2008-2010 The Padre development team as listed in Padre.pm.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.