#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}
use Test::More skip_all => 'Requires a running standalone server';
use Test::More tests => 8;

# We don't use Catalyst::Test because we need access
# to the useragent for redirects on POST 
BEGIN {
	use_ok( 'Madre::Sync::Controller::User' );
}

use URI            ();
use JSON::XS       ();
use HTTP::Cookies  ();
use LWP::UserAgent ();
use HTTP::Request::Common qw/GET POST PUT DELETE/;

# Set up browser and serializer
my $json = JSON::XS->new;
my $ua   = LWP::UserAgent->new;
push @{ $ua->requests_redirectable }, 'POST';
$ua->timeout(5);
$ua->cookie_jar(
	HTTP::Cookies->new(
		file     => "t/lwp_cookies.dat",
		autosave => 1,
	)
);

# Create account
my $req_data = { 
	username => "test_account", 
	password => "abcdefg", 
	email    => 'test@abcd.com' 
};

diag 'Add a user';
my $resp = $ua->request(
	PUT 'http://localhost:3000/register',
	'Content-Type' => 'application/json',
	'Content'      => $json->encode($req_data),
);
is( $resp->code, 200, "Account creation" );

diag $resp->status_line;
diag $resp->content;
diag $resp->status_line;
diag 'login using above created account';
$resp = $ua->request(
	POST 'http://localhost:3000/login',
	[
		username => "test_account",
		password => "abcdefg",
		email    => 'test@abcd.com',
	]
);
is( $resp->code, 200, "Login" );

diag 'Test uniqueness reregistration';
$resp = $ua->request(
	PUT 'http://localhost:3000/register',
	'Content-Type' => 'application/json',
	'Content'      => $json->encode($req_data),
);
is( $resp->code, 400, "Account creation reattempt with used email / name" );

diag 'Test updating information';
$resp = $ua->request(
	POST 'http://localhost:3000/user',
	'Content-Type' => 'application/json',
	'Content'      => $json->encode( {
		email    => 'bademial.ean',
		password => 'qwerty',
	} )
);
is( $resp->code, 400, "Account modification with invalid email address" );

$resp = $ua->request(
	POST 'http://localhost:3000/user',
	'Content-Type' => 'application/json',
	'Content'      => $json->encode( {
		email    => 'goodemail@yes.com',
		password => 'qwerty',
	} )
);
is( $resp->code, 200, "Account modification with valid email address" );

diag 'Test post of config';
$resp = $ua->request(
	POST 'http://localhost:3000/user/config',
	'Content-Type' => 'application/json',
	'Content'      => $json->encode( {
		config => { test => 'goodemail@yes.com', password => 'qwerty' }
	} )
);
is( $resp->code, 200, "Config submission" );

diag 'Test get of config';
$resp = $ua->request(
	GET 'http://localhost:3000/user/config',
	'Accept' => 'application/json',
);

#$resp = $ua->request( GET , 'Content-Type' => 'application/json', Content => $json->encode( { email => 'goodemail@yes.com', password => 'qwerty' } ) );
#$resp =$ua->request( GET 'http://localhost:3000/user/config', 'Content-Type' => 'application/json' );
#use Data::Dumper;
#diag Dumper $resp;
#diag $resp->content;

diag 'Test deletion';
$resp = $ua->request( DELETE 'http://localhost:3000/user' );
is( $resp->code, 200, "Deletion" );
