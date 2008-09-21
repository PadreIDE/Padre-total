package Padre::Document::Perl;

use 5.008;
use strict;
use warnings;
use Carp            ();
use Params::Util    '_INSTANCE';
use Padre::Document ();

our $VERSION = '0.09';
our @ISA     = 'Padre::Document';





#####################################################################
# Padre::Document::Perl Methods

sub ppi_get {
	my $self = shift;
	my $text = $self->text_get;
	require PPI::Document;
	PPI::Document->new( \$text );
}

sub ppi_set {
	my $self     = shift;
	my $document = _INSTANCE(shift, 'PPI::Document');
	unless ( $document ) {
		Carp::croak("Did not provide a PPI::Document");
	}

	# Serialize and overwrite the current text
	$self->text_set( $document->serialize );
}

sub ppi_find {
	my $self     = shift;
	my $document = $self->ppi_get;
	return $document->find( @_ );
}

sub ppi_find_first {
	my $self     = shift;
	my $document = $self->ppi_get;
	return $document->find_first( @_ );
}

sub ppi_transform {
	my $self      = shift;
	my $transform = _INSTANCE(shift, 'PPI::Transform');
	unless ( $transform ) {
		Carp::croak("Did not provide a PPI::Transform");
	}

	# Apply the transform to the document
	my $document = $self->ppi_get;
	unless ( $transform->document($document) ) {
		Carp::croak("Transform failed");
	}
	$self->ppi_set($document);

	return 1;
}

sub ppi_select {
	my $self     = shift;
	my $location = shift;
	if ( _INSTANCE($location, 'PPI::Element') ) {
		$location = $location->location;
	}
	my $page     = $self->page or return;
	my $line     = $page->PositionFromLine( $location->[0] - 1 );
	my $start    = $line + $location->[1] - 1;
	$page->SetSelection( $start, $start + 1 );
}

my $keywords = {
	chomp     => '(STRING)',
	substr    => '(EXPR, OFFSET, LENGTH, REPLACEMENT)',
	index     => '(STR, SUBSTR, INDEX)',
	pop       => '(@ARRAY)',
	push      => '(@ARRAY, LIST)',
	print     => '(LIST) or (FILEHANDLE LIST)',
	join      => '(EXPR, LIST)',
	split     => '(/PATTERN/,EXPR,LIMIT)',
	wantarray => '()',
};

sub keywords {
	return $keywords;
}

sub get_functions {
	my $self = shift;

	my $text = $self->text_get;
    return reverse sort $text =~ m{^sub\s+(\w+)}gm;
}

1;
