use Test::More;

BEGIN {
	use_ok( 'Padre::Index' );
	use_ok( 'Padre::Index::Kinosearch' );
	
	
};


my $index = Padre::Index::Kinosearch->new( index_directory => '/tmp/padre-index-kino' );
isa_ok( $index , 'Padre::Index::Kinosearch' );

my $idx = $index->indexer;
isa_ok( $idx , 'KinoSearch::Indexer' );



done_testing();
