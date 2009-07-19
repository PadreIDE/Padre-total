package Padre::Index::Kinosearch;
use strict;
use warnings;

use base qw( Padre::Index );
use KinoSearch;

use KinoSearch::Indexer;
use KinoSearch::Schema;
require  KinoSearch::Analysis::PolyAnalyzer;
use KinoSearch::FieldType::FullTextType;
use Carp qw( confess );

our $VERSION = '0.40';

=pod

=head1 NAME

Padre::Index::Kinosearch

=head1 COPYRIGHT & LICENSE

Copyright 2008-2009 The Padre development team as listed in Padre.pm.

This program is free software; you can redistribute it and/or modify it under the
same terms as Perl 5 itself.

=cut

# Create a Schema which defines index fields.

sub typemap {
    my $polyanalyzer =  KinoSearch::Analysis::PolyAnalyzer->new( language=>'en' );
    warn $polyanalyzer;

    my %typemap = (
        static => KinoSearch::FieldType::StringType->new(),
        number => KinoSearch::FieldType::StringType->new(),
        text   => KinoSearch::FieldType::FullTextType->new(analyzer => $polyanalyzer ),
    );    
    
    %typemap;
}

sub schema { 
    my $class = shift;
    my $schema = KinoSearch::Schema->new;

    my %fields = $class->index_fields;
    my %typemap = $class->typemap;
    while ( my ($field,$type) = each %fields ) {
        my $kinotype = $typemap{$type};
        confess "Cannot map index_field type '$type'" unless $kinotype;
        $schema->spec_field( name => $field , type => $kinotype );
    }
    
    return $schema
    
}

sub indexer {
    my $self = shift;
    my $schema = $self->schema;
    warn "Indexer in ". $self->index_directory;
    
# Create the index and add documents.
    my $indexer = KinoSearch::Indexer->new(
        schema => $schema,   
        index  => $self->index_directory,
        create => 1,
    );

}

sub index {
    my $self = shift;
    my $search = KinoSearch::Searcher->new( index=> $self->index_directory );
}


1;


# Copyright 2008-2009 The Padre development team as listed in Padre.pm.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.