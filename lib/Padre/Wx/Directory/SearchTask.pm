package Padre::Wx::Directory::SearchTask;
use strict;
use warnings;

our $VERSION = '0.41';
use base 'Padre::Task';

sub current {
	Padre::Current->new();
}

sub run {
	my $self      = shift;
	my $search    = $self->current->main->directory->{search};
	my $word      = $self->{word};

	# Sleeps of 0.4 seconds to check if the
	# use is still typing
	select(undef, undef, undef, 0.4);

	# Returns if the typed word when called the search
	# is different from the currently word
	return "BREAK" if $word ne $search->GetValue;

	my $directory = $self->{directory};

	require Padre::Wx::Directory::SearchTask2;
	my $task = Padre::Wx::Directory::SearchTask2->new(
			project_dir => $directory->project_dir,
			tree        => $directory->{tree},
			search      => $directory->{search},
			cache       => $self->{cache},
			word        => $word,
		);
	$task->schedule;

	return 1;
}

sub finish {
	my $self = shift;
	my $word = $self->{word};
	print "finalized $word$/";
}

1;
