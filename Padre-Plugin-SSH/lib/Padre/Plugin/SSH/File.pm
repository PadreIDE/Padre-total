package Padre::Plugin::SSH::File;

use 5.008;
use strict;
use warnings;

our $VERSION = '0.50';
our @ISA     = 'Padre::File';

use Class::XSAccessor {
	false => [qw/can_run/],
	accessors => [qw/user hostname remote_file port/],
	getters => [qw/ssh tmpfile file_temp/],
};

sub _guess_username {
	my $self = shift;
	my $username;
	my $pwuid;
	# does not work everywhere:
	eval {($pwuid) = getpwuid($>) if defined $>;};

	if ( defined(&Win32::LoginName) ) {
		$username = &Win32::LoginName;
	}
	elsif (defined $pwuid) {
		$username = $pwuid;
	}
	else {
		$username = $ENV{USERNAME} || $ENV{USER} || 'anonymous';
	}
	return $username;
}

sub new {
	my $class = shift;
	require File::Temp;
	require Net::SSH::Perl;

	my $url = shift;

	# Create myself
	my $self = bless { filename => $url } => $class;

	# Using the config is optional, tests and other usages should run without
	my $config = eval { return Padre->ide->config; };
	if ( defined($config) ) {
	#	$self->{_timeout} = $config->file_ftp_timeout;
	#	$self->{_passive} = $config->file_ftp_passive;
	} else {

		# Use defaults if we have no config
	#	$self->{_timeout} = 60;
	#	$self->{_passive} = 1;
	}


	# most complicated allowed syntax: ssh://user:password@hostname:port:/path/to/file

	my @matches = $url =~ m{
		^ ssh://
		(?:				# begin optional user:password@ section
			(\w+)			# user name
			(?: : ([^@]+) )?	# colon followed by optional password
			@
		)?				# end optional user:password@section
		([^/:]+)			# hostname
		(?: : (\d+) :? )?		# optional port
		(?: (.*))			# path
		$
	}x;
	if (not @matches or not defined $matches[-1]) {
		$self->{error} = 'Unable to parse URL "' . $url . '"';
		return $self;
	}
	
	my ($user, $password, $hostname, $port, $file_path) = @matches;
	$user = $self->_guess_username() if not defined $user;
	require utf8;
	utf8::downgrade($user);
	$self->user($user);
	$self->hostname($hostname);
	$self->port(defined $port ? $port : 22);
	$self->remote_file($file_path);

	#if ( !defined( $password ) ) {
	# TO DO: Ask the user for a password
	#}

	# TO DO: Handle aborted/timed out connections

	# Create SSH object and connection
	$self->{ssh} = Net::SSH::Perl->new(
		$self->hostname,
		interactive    => 0,
		protocol       => 2, # support SSH2 only for security reasons...
		port           => $self->port,
		use_pty        => 0, # no interactivity
		debug          => 1, # FIXME remove
		#cipher         => ...,
		#identity_files => ... # TODO: allow configuration
	);
	
	$self->ssh->login($self->user, $password, 0);
	
	if (not eval {$self->ssh->sock}) {
		%$self = (error => 'Could not connect to host');
		return $self;
	}

	$self->{file_temp} = File::Temp->new( UNLINK => 1 );
	$self->{tmpfile} = $self->{file_temp}->filename;

	return $self;
}

sub _todo_size {
	my $self = shift;
	#return if !defined( $self->{_ftp} );
	#return $self->{_ftp}->size( $self->{_file} );
}

sub _todo_mode {
	my $self = shift;
	return 33024; # Currently fixed: read-only textfile
}

sub _todo_mtime {
	my $self = shift;

	# The file-changed-on-disk - function requests this frequently:
	if ( defined( $self->{_cached_mtime_time} ) and ( $self->{_cached_mtime_time} > ( time - 60 ) ) ) {
		return $self->{_cached_mtime_value};
	}

	require HTTP::Date; # Part of LWP which is required for this module but not for Padre
	my ( $Content, $Result ) = $self->_request('HEAD');

	$self->{_cached_mtime_value} = HTTP::Date::str2time( $Result->header('Last-Modified') );
	$self->{_cached_mtime_time}  = time;

	return $self->{_cached_mtime_value};
}

sub _todo_exists {
	my $self = shift;
	return if !defined( $self->{_ftp} );

	# Cache basename value
	my $basename = $self->basename;

	for ( $self->{_ftp}->ls( $self->{_file} ) ) {
		return 1 if $_ eq $self->{_file};
		return 1 if $_ eq $basename;
	}

	# Fallback if ->ls didn't help. A file heaving a size should exist.
	return 1 if $self->size;

	return();
}

sub _todo_basename {
	my $self = shift;

	my $name = $self->{_file};
	$name =~ s/^.*\///;

	return $name;
}

# This method should return the dirname to be used inside Padre, not the one
# used on the FTP-server.
sub _todo_dirname {
	my $self = shift;

	my $dir = $self->{filename};
	$dir =~ s/\/[^\/]*$//;

	return $dir;
}

sub _todo_read {
	my $self = shift;

	return if !defined( $self->{_ftp} );

	# TO DO: Better error handling
	$self->{_ftp}->get( $self->{_file}, $self->{_tmpfile} ) or $self->{error} = $@;
	open my $tmpfh, $self->{_tmpfile};
	return join( '', <$tmpfh> );
}

sub _todo_readonly {
	# TO DO: Check file access
	return();
}

sub _todo_write {
	my $self    = shift;
	my $content = shift;
	my $encode  = shift || ''; # undef encode = default, but undef will trigger a warning

	return if !defined( $self->{_ftp} );

	my $fh;
	if ( !open $fh, ">$encode", $self->{_tmpfile} ) {
		$self->{error} = $!;
		return();
	}
	print {$fh} $content;
	close $fh;

	# TO DO: Better error handling
	$self->{_ftp}->put( $self->{_tmpfile}, $self->{_file} ) or warn $@;

	return 1;
}



1;

# Copyright 2008-2009 The Padre development team as listed in Padre.pm.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.
