package Padre::Document::LaTeX::Outline;

# ABSTRACT: LaTeX document support for Padre

use 5.008;
use strict;
use warnings;
use Padre::Task::Outline ();

our @ISA = 'Padre::Task::Outline';

our $VERSION = '0.14';

sub find {
	my $self = shift;
	my $text = shift;

	# remove all comments
	$text =~ s/[^\\]%.*//g;

	warn "Text: $text\n";

	# Build the outline structure from the search results
	my @outline       = ();
	my $cur_pkg       = { name => 'latex file' };

	push @outline, $cur_pkg;

	return \@outline;
}

1;
