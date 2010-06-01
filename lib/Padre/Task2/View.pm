package Padre::Task2::View;

# Sub-class for tasks which are tied to a particular GUI tool
# (as identifiable by being isa Padre::Wx::Role::View)

use 5.008;
use strict;
use warnings;
use Params::Util          ();
use Padre::Task2          ();
use Padre::Wx::Role::View ();

our $VERSION = '0.62';
our @ISA     = 'Padre::Task2';

# Allow passing the Wx object itself as the view
sub new {
	my $class = shift;
	my $self  = $class->SUPER::new(@_);
	if ( Params::Util::_INSTANCE($self->{view}, 'Padre::Wx::Role::View') ) {
		$self->{view} = $self->{view}->revision;
	}
	unless ( Params::Util::_POSINT($self->{view}) ) {
		die "Did not provide a view id to Padre::Task2::View task";
	}
	return $self;
}

# Fetch the view for the task, if it still exists
sub view {
	Padre::Wx::Role::View->revision_fetch($_[0]->{view});
}

1;
