package Madre::Dance::Sync;

use 5.008;
use strict;
use Digest::MD5                ();
# use Data::Dumper               ();
use JSON                       ();
use DateTime                   ();
use DateTime::Format::Strptime ();
use Try::Tiny;
use Madre::DB;
use Dancer;

our $VERSION = '0.1';

my $DATES = DateTime::Format::Strptime->new(
    pattern => '%F %T %z',
);

set serializer => 'mutable';

hook before => sub {
    my $session = session('user');
    if ( $session ) {
        try {
            my $user = Madre::DB::User->load($session);
            debug( 'Loaded session user - ' . $user->username );
            vars->{user} = $user;

        } catch {
            debug( "Invalid session user $session" );
            session->destroy;
        };
    }
};





######################################################################
# Site Registration

get '/register' => sub {
    template 'register.tt', {
        title => 'Registration',
    };
};

post '/register' => sub {
    my $username  = params->{username};
    my $password1 = params->{password};
    my $password2=  params->{password_confirm};
    my $email1    = params->{email};
    my $email2    = params->{email_confirm};
    # debug( Dumper params() );

    # Validate the user information
    unless ( length $password1 ) {
        return register_error("You must supply a password");
    }
    unless ( length $email1 ) {
        return register_error("You must supply an email address");
    }
    unless ( length $username ) {
        return register_error("You must provide a username");
    }
    unless ( $password1 eq $password2 ) {
        return register_error("Passwords do not match");
    }
    unless ( $email1 eq $email2 ) {
        return register_error("Email addresses do not match");
    }

    try {
        my $user = Madre::DB::User->create(
            username => $username,
            password => salt_password( $username, $password1 ),
            email    => $email1,
            created  => $DATES->format_datetime( DateTime->now ),
        ) or die "Failed to create user";

        my $location = '/user/name/' . $username;
        status 201; # Created
        header 'Location' => $location;
        template 'created.tt', {
            user     => $user,
            user_uri => $location,
        };

    } catch {
        debug( "$_") ;
        status 500; # Internal error
        return {
            error => $_,
            title =>'Registration',
        };
    };
};

sub register_error ($) {
    status 500;
    template 'register.tt', {
        title => 'Registration',
        error => "$_[0]\n",
    };
}





######################################################################
# Login Management

any '/logout' , sub {
        session->destroy;
        redirect '/';
};

get '/login' , sub {
       template 'login.tt';
};

post '/login' , sub {
        my $username = params->{username};
        my $password = params->{password};
        my $hash     = salt_password( $username, $password );
        debug( "Using hash = $hash" );

        my ($user) = try {
            Madre::DB::User->select(
                'WHERE username = ? AND password = ?',
                $username,
                $hash,
            );
        };

        debug($user);
        if ( $user ) {
            debug "Success ", $user;
            session user => $user->id;
            session logged_in => true;
            redirect '/';
        } else {
           debug( "Auth failed" );
           error "Authorisation failed";
           status 401;
           return 'authentication failure';
        }
};





######################################################################
# Configuration Management

get '/config' => sub {
    my $session = session('user');
    unless ( $session ) {
        status 401;
        return template 'login';
    }

    my ($config) = Madre::DB::Config->select(
        'WHERE user_id = ? ORDER BY modified DESC',
        $session,
    );

    my $hash = JSON::decode_json( $config->data );
    status 200;
    return $hash;
};

put '/config' => sub {
    my $session = session('user');
    unless ( $session ) {
            status 401;
            return template 'login';
    }
    # debug( Dumper params() );

    my ($conf) =  Madre::DB::Config->select(
        'WHERE user_id = ?',
        $session,
    );

    my %payload = params();
    # debug "Got payload " . Dumper \%payload;
    Madre::DB->do(
        'INSERT INTO config ( user_id, data ) VALUES ( ?, ? )', {},
        $session,
        JSON::encode_json( \%payload ),
    );

    status 204;
};





######################################################################
# General Views

get '/user/*' => sub {
    my ($name) = splat;

    # Find the user
    my ($user) = try {
        Madre::DB::User->select(
            'WHERE username = ?',
            $name,
        );
    };
    unless ( $user ) {
        die "Missing or invalid user '$name'";
    }

    # Find their configuration
    my ($config) = Madre::DB::Config->select(
        'WHERE user_id = ? ORDER BY modified DESC',
        $user->id,
    );

    # Build the user page
    template 'user.tt' , {
        user => $user,
        conf => $config,
    };
};





######################################################################
# Support Functions

sub salt_password {
    my ($username, $password) = @_;
    my $salt = substr( $username , 0, 1 ) . substr($username, -1,1);
    my $hash = Digest::MD5::md5_hex( $salt  .  $password );
    return "$salt:$hash";
};

1;
