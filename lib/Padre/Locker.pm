package Padre::Locker;

=pod

=head1 NAME

Padre::Locker - The Padre Multi-Resource Lock Manager

=cut

use 5.008;
use strict;
use warnings;
use Padre::Lock ();
use Padre::DB   ();
use Padre::Logger;

our $VERSION = '0.74';

sub new {
	my $class = shift;
	my $owner = shift;

	# Create the object
	my $self = bless {
		owner => $owner,

		# Padre::DB Transaction lock
		db_depth => 0,

		# Padre::Config Transaction lock
		config_depth => 0,

		# Wx ->Update lock
		update_depth  => 0,
		update_locker => undef,

		# Wx "Busy" lock
		busy_depth  => 0,
		busy_locker => undef,

		# Padre ->refresh lock
		method_depth   => 0,
		method_pending => {},
	}, $class;
}

sub lock {
	Padre::Lock->new( shift, @_ );
}

sub locked {
	my $self  = shift;
	my $asset = shift;
	if ( $asset eq 'UPDATE' ) {
		return !!$self->{update_depth};
	} elsif ( $asset eq 'BUSY' ) {
		return !!$self->{busy_depth};
	} elsif ( $asset eq 'REFRESH' ) {
		return !!$self->{method_depth};
	} elsif ( $asset eq 'CONFIG' ) {
		return !!$self->{config_depth};
	} else {
		return !!$self->{method_pending}->{$asset};
	}
}

# During Padre shutdown we should disable all forms of screen updating,
# once we have completed all user-interactive steps in the shutdown.
# Calling the shutdown method will permanently ignore any and all attempts
# to call refresh methods.
# This method does NOT ->Hide the actual application, that is left up to the
# shutdown process. This action just disables everything lock-related that
# might slow the shutdown process.
sub shutdown {
	my $self = shift;
	my $lock = $self->lock( 'UPDATE', 'REFRESH', 'CONFIG' );
	$self->{shutdown} = 1;

	# If we have an update lock running, stop it manually now.
	# If we don't do this, Win32 Padre will segfault on exit.
	$self->{update_locker} = undef;

	return 1;
}





######################################################################
# Locking Mechanism

# Database locking like this is only possible because Padre NEVER makes
# use of rollback. All bad database requests are considered fatal.

sub db_increment {
	my $self = shift;
	unless ( $self->{db_depth}++ ) {
		Padre::DB->begin;

		# Database operations we lock on are the most likely to
		# involve writes. So opportunistically prevent blocking
		# on filesystem sync confirmation. This should make
		# database write operations faster, at the risk of config.db
		# corruption if (and only if) there is a power outage,
		# operating system crash, or catastrophic hardware failure.
		Padre::DB->pragma( 'synchronous' => 0 );
	}
	return;
}

sub db_decrement {
	my $self = shift;
	unless ( --$self->{db_depth} ) {
		Padre::DB->commit;
	}
	return;
}

sub config_increment {
	my $self = shift;
	unless ( $self->{config_depth}++ ) {

		# TO DO: Initiate config locking here
		# NOTE: Pretty sure we don't need to do anything specific
		# here for the config file stuff.
	}
	return;
}

sub config_decrement {
	my $self = shift;
	unless ( $self->{config_depth}-- ) {

		# Write the config file here
		$self->owner->config->write;
	}
	return;
}

sub update_increment {
	my $self = shift;
	unless ( $self->{update_depth}++ ) {

		# When a Wx application quits with ->Update locked, windows will segfault.
		# During shutdown, do not allow the application to enable an update lock.
		# This should be pointless anyway, because the window shouldn't be visible.
		return if $self->{shutdown};

		# Locking for the first time
		$self->{update_locker} = Wx::WindowUpdateLocker->new( $self->{owner} );
	}
	return;
}

sub update_decrement {
	my $self = shift;
	unless ( --$self->{update_depth} ) {
		return if $self->{shutdown};

		# Unlocked for the final time
		$self->{update_locker} = undef;
	}
	return;
}

sub busy_increment {
	my $self = shift;
	unless ( $self->{busy_depth}++ ) {

		# If we are in shutdown, the application isn't painting anyway
		# (or possibly even visible) so don't put us into busy state.
		return if $self->{shutdown};

		# Locking for the first time
		$self->{busy_locker} = Wx::BusyCursor->new;
	}
	return;
}

sub busy_decrement {
	my $self = shift;
	unless ( --$self->{busy_depth} ) {
		return if $self->{shutdown};

		# Unlocked for the final time
		$self->{busy_locker} = undef;
	}
	return;
}

sub method_increment {
	$_[0]->{method_depth}++;
	$_[0]->{method_pending}->{ $_[1] }++;
	return;
}

sub method_decrement {
	my $self = shift;
	$self->{method_pending}->{ $_[0] }--;
	unless ( --$self->{method_depth} ) {

		# Once we start the shutdown process, don't run anything
		return if $self->{shutdown};

		# Optimise the refresh methods
		$self->method_trim;

		# Run all of the pending methods
		foreach ( keys %{ $self->{method_pending} } ) {
			next if $_ eq uc $_;

			# This call is sent into what is essentially
			# arbitrary code, and it's easy for exceptions
			# under here to cause the entire locking sub-system
			# to crash. Trap and ignore errors so we can attempt
			# to retain the integrity of the locking subsystem
			# as a whole.
			local $@;
			eval { $self->{owner}->$_(); };
			if ( DEBUG and $@ ) {
				TRACE("ERROR: '$@'");
			}
		}
		$self->{method_pending} = {};
	}
	return;
}

# Optimise the refresh by removing low level refresh methods that are
# contained within high level refresh methods we need to run anyway.
sub method_trim {
	my $self    = shift;
	my $pending = $self->{method_pending};
	if ( defined $pending->{refresh} ) {
		delete $pending->{refresh_menu};
		delete $pending->{refresh_toolbar};
		delete $pending->{refresh_status};
		delete $pending->{refresh_functions};
		delete $pending->{refresh_directory};
	}
	return;
}

1;

# Copyright 2008-2010 The Padre development team as listed in Padre.pm.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.
