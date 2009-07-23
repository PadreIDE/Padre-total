#!/usr/bin/perl
use lib qw( lib );
use Pod::Abstract;
use File::Find;

use Padre::Index::Kinosearch;

my $index = Padre::Index::Kinosearch->new( index_directory => '/tmp/padre-index' );

#my $hits = $search->hits( query => join(' ',@ARGV)  , offset=>0, num_wanted=>10);
my $hits = $index->search( join( ' ' , @ARGV ) );

while ( my $hit = $hits->next ) {
    print "$hit->{title}\t" . $hit->get_score . $/;
}

