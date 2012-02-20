package Madre::Dance::Sync;

use 5.008;
use strict;
use Digest::MD5                ();
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
    my $user_id = session('user');
    if ( $user_id ) {
        try {
            my $user = Madre::DB::User->load($user_id);
            debug( 'Loaded session user - ' . $user->username );
            vars->{user} = $user;
        } catch {
            debug( "Invalid session user $user_id" );
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
    my $email1    = params->{email};
    my $email2    = params->{email_confirm};
    my $password1 = params->{password};
    my $password2 = params->{password_confirm};

    # Validate the user information
    unless ( length $email1 ) {
        return register_error("You must supply an email address");
    }
    unless ( $email1 eq $email2 ) {
        return register_error("Email addresses do not match");
    }
    unless ( length $password1 ) {
        return register_error("You must supply a password");
    }
    unless ( $password1 eq $password2 ) {
        return register_error("Passwords do not match");
    }

    try {
        my $user = Madre::DB::User->create(
            email    => $email1,
            password => salt_password( $email1, $password1 ),
        ) or die "Failed to create user";

        my $location = '/user/' . $user->user_id;
        status 201; # Created
        header 'Location' => $location;
        template 'created.tt', {
            user => $user,
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
        my $email    = params->{email};
        my $password = params->{password};
        my $hash     = salt_password( $email, $password );
        debug( "Using hash = $hash" );

        my ($user) = try {
            Madre::DB::User->select(
                'WHERE username = ? AND password = ?',
                $email,
                $hash,
            );
        };

        debug($user);
        unless ( $user ) {
           debug( "Auth failed" );
           status 401;
           return 'authentication failure';
        }

        debug "Success ", $user;
        session user => $user->user_id;
        session logged_in => true;
        redirect '/';
};





######################################################################
# Configuration Management

get '/config' => sub {
    my $user_id = session('user');
    unless ( $user_id ) {
        status 401;
        return template 'login';
    }

    my ($config) = Madre::DB::Config->select(
        'WHERE user_id = ? ORDER BY modified DESC LIMIT 1',
        $user_id,
    );

    my $hash = JSON::decode_json( $config->data );
    status 200;
    return $hash;
};

put '/config' => sub {
    my $user_id = session('user');
    unless ( $user_id ) {
            status 401;
            return template 'login';
    }

    my %payload = params();
    Madre::DB::Config->create(
        user_id => $user_id,
        data    => JSON::encode_json( \%payload ),
    );

    status 204;
};





######################################################################
# General Views

get '/user/*' => sub {
    my ($user_id) = splat;

    # Find the user
    my $user = try {
        Madre::DB::User->load($user_id);
    };
    unless ( $user ) {
        die "Missing or invalid user '$user_id'";
    }

    # Find their configuration
    my ($config) = Madre::DB::Config->select(
        'WHERE user_id = ? ORDER BY modified DESC LIMIT 1',
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
    my ($email, $password) = @_;
    my $salt = substr( $email , 0, 1 ) . substr($email, -1,1);
    my $hash = Digest::MD5::md5_hex( $salt  .  $password );
    return "$salt:$hash";
};

1;
