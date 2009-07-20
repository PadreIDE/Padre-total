use Test::More;

BEGIN {
	use_ok( 'Padre::Index' );
	use_ok( 'Padre::Index::Kinosearch' );
	
	
};


my $index = Padre::Index::Kinosearch->new( index_directory => '/tmp/padre-index-kino-'.$$ );
isa_ok( $index , 'Padre::Index::Kinosearch' );

my $idx = $index->indexer;
isa_ok( $idx , 'KinoSearch::Indexer' );

foreach my $id ( 1..10 ) {
	my $doc = { title=>$id , content=>"test $id", modified=>time() };
	$index->add_document( $doc );
}
$index->commit;


my $hits = $index->search( query => 'test 5' );
ok( $hits->total_hits );



done_testing();
