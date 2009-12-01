package Padre::Plugin::wxGlade::WXG;

use strict;
use warnings;
# use XML::Tiny ();

our $VERSION = '0.01';

sub new {
	my $class = shift;
	my $file  = shift;

	# Parse the XML file
	require XML::Tiny;
	my $document = XML::Tiny::parsefile( $file );

	# Extract application properties
	my $application = $document->[0];

	# Create the WXG object
	my $self = bless { }, $class;

	return $self;
}

1;
