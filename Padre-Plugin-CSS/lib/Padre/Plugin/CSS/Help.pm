package Padre::Plugin::CSS::Help;

use 5.008;
use strict;
use warnings;
use Carp        ();
use Padre::Help ();

our $VERSION = '0.22';
our @ISA     = 'Padre::Help';


my %topics = (
	'padding' => 'length | percentage (4 values), inherit',
	'color'   => 'Color of an element. Values can be RGB: #AABBCC',
);

sub help_init {
	my ($self) = @_;

	# TODO read the "topics" from some external file?

	return;
}

sub help_list {
	my ($self) = @_;

	return [keys %topics];
}

sub help_render {
	my ( $self, $topic ) = @_;

warn "'$topic'";
	$topic =~ s/://;
	my $html = "$topic $topics{$topic}";
	my $location = $topic;
	return ( $html, $location );
}

1;

