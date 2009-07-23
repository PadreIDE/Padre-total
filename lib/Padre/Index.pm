package Padre::Index;

use strict;
use warnings;

use Params::Util qw( _HASH );
use Carp qw( croak );
use Class::XSAccessor 
	constructor => 'new',
	accessors => {
		index_directory => 'index_directory', 
		clobber => 'clobber',
		_writer => '_writer',
		_reader => '_reader',
	};
	
our $VERSION = '0.40';

=pod

=head1 NAME

Padre::Index - Index/Retrieve utility

=head1 SYNOPSIS

  my $index = Padre::Index->new( index_directory => '/tmp/myindex' );
  $index->add_doc( $_ ) for @documents;
  $index->commit;
  
  my $iterator = $index->search( 'fast accessor' );
  while ( my $hit = $iterator->next ) {
		print $hit->{title} . "\n";
  }
  
=head1 DESCRIPTION

Generic class describing the interface. Provides a constructor and default 
properties.

=head1 CLASS METHODS


=head2 index_fields

Returns a list of key value pairs where keys are field names and values are 
informal datatype names

=head1 COPYRIGHT & LICENSE

Copyright 2008-2009 The Padre development team as listed in Padre.pm.

This program is free software; you can redistribute it and/or modify it under the
same terms as Perl 5 itself.

=cut
	
sub index_fields { 
	( 
		title 		=> 'text',
		content 	=> 'text',
		keywords	=> 'text',
		modified 	=> 'number',
		resource 	=> 'static',
		file 		=> 'static',
		payload		=> 'blob',
	)
};

sub schema { croak "Index subclass must implement schema!"; }

sub query {
	my ($self,$query) = @_;
	$self->index->query( $query );
	
}

sub add_document {
	my ($self,$doc) = @_;
	$self->indexer->add_doc( $doc );
}

sub commit { croak "Index subclass must implement 'commit'" }

1;

# Copyright 2008-2009 The Padre development team as listed in Padre.pm.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.