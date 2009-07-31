package Padre::Wx::Directory::SearchTask;
use Padre::Wx::Directory::SearchTask2;
use strict;
use warnings;

our $VERSION = '0.41';
use base 'Padre::Task';

sub current {
	Padre::Current->new();
}

sub run {
	my $self      = shift;
	my $current   = $self->current;
	my $directory = $current->main->directory;
	my $search    = $directory->{search};
	my $word      = $search->GetValue;

	# Sleeps of 0.4 seconds to check if the
	# use is still typing
	select(undef, undef, undef, 0.4);

	# Returns if the typed word when called the search
	# is different from the currently word
	return if $word ne $search->GetValue;

	my $task = $self->task( $self->{directoryx}, $self->{cache} );
	$task->schedule;
}

sub task {
	$_[0]->{task}
	or
	$_[0]->{task} = do {
		Padre::Wx::Directory::SearchTask2->new( directoryx => $_[1], cache => $_[2] );
	}
}

1;
