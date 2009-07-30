package Padre::Wx::Directory::SearchTask;
use Padre::Wx::Directory::SearchTask2;
use strict;
use warnings;

our $VERSION = '0.41';
use base 'Padre::Task';

sub run {
	my $self = shift;
	my $task = Padre::Wx::Directory::SearchTask2->new( directoryx => $self->{directoryx}, cache => $self->{cache});
	$task->schedule;
}

1;

