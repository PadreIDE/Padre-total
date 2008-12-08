package CPAN::Shell::Wx;

use strict;
use warnings;

our $VERSION = '0.01';

use CPAN;
use CPAN::Shell::Wx::App;

sub new {
	my ($class) = @_;

	$CPAN::Frontend ||= "CPAN::Shell::Wx::Front";

	return bless {}, $class;
}

sub run {
	my ($self) = @_;
	CPAN::Shell::Wx::App->new;
}


1;
