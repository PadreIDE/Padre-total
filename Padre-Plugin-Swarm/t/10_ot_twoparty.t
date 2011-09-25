use Test::More tests => 1;
use Data::Dumper;
use t::lib::OTDoc;
use Padre::Plugin::Swarm::Resource;

my $owner = t::lib::OTDoc->new(<<ORIGIN
.+,.+,.+,.+,.+,.+,.+,.+,.+,.+,
ORIGIN
);
my $owner_resource = 
        Padre::Plugin::Swarm::Resource->new(
                id   => "$owner",
                body => $$owner,
                
        );
my $remote = t::lib::OTDoc->new($$owner);
my $remote_resource = 
        Padre::Plugin::Swarm::Resource->new(
                id   => "$owner",
                body => $$remote,
        );

## my edits
my @owner_edits = (
# seq  dtime  op       pos  body
[ 1  , 0   , 'insert' , 0, ''  ], # document opened
[ 2  , 0.1 , 'insert' , 5, 'a' ],
[ 3  , 0.5 , 'insert' , 6, 'b' ],
[ 4  , 1.0 , 'delete' , 5, 'a' ],
);

## remote edits
my @remote_edits = (
[ 2  , 0.2 ,  'insert' , 7, 'x'  ],
[ 3  , 0.4 ,  'insert' , 1, 'y'  ],
[ 4  , 0.9 ,  'delete' , 8, 'x'  ], 
);

$remote_resource->perform_edit( $_ ) for @remote_edits;
$owner_resource->perform_edit( $_ ) for @owner_resource;
##
#diag( Dumper $remote_resource );

TODO: {
        local $TODO = 'work in progress';
        ok( $$owner ne $$remote  , 'Documents differ after isolated edits' );
}