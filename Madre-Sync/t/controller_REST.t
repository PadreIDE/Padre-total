use strict;
use warnings;
use Test::More tests => 8;

# we dont use Catalyst::Test because we need access to the useragent for redirects on POST 
#BEGIN { use_ok 'Catalyst::Test', 'Madre::Sync' }
BEGIN {
	use_ok( 'Madre::Sync::Controller::User' );
}

use LWP::UserAgent;
use HTTP::Cookies;
use HTTP::Request::Common qw/GET POST PUT DELETE/;
use JSON::Any;
use URI;

# set up browser and serializer
my $j = JSON::Any->new;
my $ua = LWP::UserAgent->new;

push @{ $ua->requests_redirectable }, 'POST';


my $cookie_jar = HTTP::Cookies->new(
   file => "$ENV{'HOME'}/lwp_cookies.dat",
   autosave => 1,
);

$ua->cookie_jar($cookie_jar);

# create account

my $resp;

my $req_data = { 
   username => "test_account", 
   password => "abcdefg", 
   email => 'test@abcd.com' 
};

#diag 'Add a user';
$resp = $ua->request( PUT 'http://localhost:3000/register', 'Content-Type' => 'application/json', Content => $j->objToJson($req_data) );
is ($resp->code, 200, "Account creation");

#diag $resp->status_line;
#diag $resp->content;
#diag $resp->status_line;

#diag 'login using above created account';
$resp = $ua->request( POST 'http://localhost:3000/login', [ username => "test_account",password => "abcdefg",email => 'test@abcd.com'] );
is ($resp->code, 200, "Login");


# test uniqueness reregistration
$resp = $ua->request(PUT 'http://localhost:3000/register', 'Content-Type' => 'application/json', Content => $j->objToJson($req_data) );
is ($resp->code, 400, "Account creation reattempt with used email / name");

# test updating information 
$resp = $ua->request( POST 'http://localhost:3000/user', 'Content-Type' => 'application/json', Content => $j->objToJson( { email => 'bademial.ean', password => 'qwerty' } ) );
is ($resp->code, 400, "Account modification with invalid email address");

$resp = $ua->request( POST 'http://localhost:3000/user', 'Content-Type' => 'application/json', Content => $j->objToJson( { email => 'goodemail@yes.com', password => 'qwerty' } ) );
is ($resp->code, 200, "Account modification with valid email address");

#test post of config 
$resp = $ua->request( POST 'http://localhost:3000/user/config', 'Content-Type' => 'application/json', Content => $j->objToJson( { config => { test => 'goodemail@yes.com', password => 'qwerty' } } ) );
is ($resp->code, 200, "Config submission");

# test get of config
$resp = $ua->request( GET 'http://localhost:3000/user/config', 'Accept' => 'application/json');

#$resp = $ua->request( GET , 'Content-Type' => 'application/json', Content => $j->objToJson( { email => 'goodemail@yes.com', password => 'qwerty' } ) );
#$resp =$ua->request( GET 'http://localhost:3000/user/config', 'Content-Type' => 'application/json' );
#use Data::Dumper;
#diag Dumper $resp;
#diag $resp->content;

# test deletion
$resp = $ua->request( DELETE 'http://localhost:3000/user' );
is ($resp->code, 200, "Deletion");

