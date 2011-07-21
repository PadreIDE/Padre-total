package Madre::Dance::Sync;
use Dancer;
use Madre::DB;
set serializer => 'mutable';

prefix '/user';

get '/id/*' => sub {
    my ($userid) = splat;
    my $user = Madre::DB::User->load( $userid );
    return $user;
};

get '/name/*' => sub {
    my ($username) = splat;
    my $user = Madre::DB::User->select( 'where username = ? ',$username );
    return $user;
};

1;
