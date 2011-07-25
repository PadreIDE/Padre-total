package Madre::Dance::Sync;
use Dancer;
use Madre::DB;
use Digest::MD5 'md5_hex';
use Data::Dumper;
use JSON 'decode_json' , 'encode_json' ;

set serializer => 'mutable';

before sub {
  if ( session('user') ) {
        my ($u) = eval { Madre::DB::User->load(session('user')) };
        if ($@) {
            session->destroy;
        } else {
            vars->{user} = $u;
        }
  }
    
};

get '/user/*' => sub {
    my ($username) = splat;
    my $users = Madre::DB::User->select( 'where username = ? ',$username );
    # Single row.
    if ( @$users == 1 ) {
        return template 'user.tt' , $users->[0];
    } else {
        die "Unexpected multirow select for username '$username'";
    }
};

get '/register' => sub {
    return template 'register.tt', { title=>'Registration' } ;
    
};

post '/register' => sub {
    my $nickname        = params->{username};
    my $password        = params->{password};
    my $password_confirm= params->{password_confirm};
    
    my $email           = params->{email};
    my $email_confirm   = params->{email_confirm};
    debug( Dumper params() );
    
    # Some validation before we touch the database
    {
        local $@;
        eval {
            if ($password ne $password_confirm) {
                die "Passwords do not match\n";
            } elsif  ($email ne $email_confirm ) {
                die "Email addresses do not match\n";
            } elsif ( length($password) == 0 ) {
                die "You must supply a password\n";
            } elsif ( length($email) == 0 ) {
                die "You must supply an email address\n";
            } elsif ( length($nickname) == 0) {
                die "You must provide a username\n";
            }
        };
        
        if ($@) {
            status 500;
            return template 'register.tt', { error=>$@, title=>'Registration' };
        }
        
    }

    
    my $pw_hash = _SALT_PW($nickname,$password);
    
    
    
    
    my $user = eval { 
            Madre::DB::User->create( 
                username => $nickname,
                password => $pw_hash,
                email    => $email,
            );
        };
    
    if ($@ or ! defined $user) {
        debug( "$@ $user") ;
        status 500; # Internal error
        return { error => $@ , title=>'Registration' } ;
    } else {
        my $location = '/user/name/' . $nickname;
        status 201; # Created
        header 'Location' => $location;
        return template 'created.tt' ,{ user=>$user, user_uri => $location };
    }


};

any '/logout' , sub {
        session->destroy;
        redirect '/';
 };
 
get '/login' , sub {
       return template 'login.tt';
};

post '/login' , sub {
        my $nickname = params->{username};
        my $password = params->{password};
            
        my $hash = _SALT_PW( $nickname,$password);
        debug( "USing hash = $hash" );
        my ($result) = 
            eval {
                Madre::DB::User->select(
                    'WHERE username=? AND password=?',
                    $nickname , $hash
                );
            };
        
        error $@ if $@;
        
        if ($result) {
                my $user = $result;
                debug "Success "  , $user;
                
                session user => $user->id;
                session logged_in => true;
                redirect '/';
                
        } else {
           debug( "Auth failed" );
           status 401;
           return 'authentication failure';
        }
        
 }      ;
 
 
 
 
 get '/config' => sub {
        unless ( session('user') ) {
            status 401;
            return template 'login';
        }
        my ($config) = Madre::DB::Config->select(
            'WHERE user_id = ? ORDER BY modified DESC' , session('user') 
        );
        
        my $hash = decode_json( $config->data );
        status 200;
        return $hash;
        
        #return $config->config;
 };


put '/config' => sub {
    unless ( session('user') ) {
            status 401;
            return template 'login';
    }
    debug( Dumper params() );
        
    my ($conf) =  Madre::DB::Config->select( 
        'WHERE user_id = ?', session('user') 
    );
    
    my %payload = params();
    debug "Got payload " . Dumper \%payload;
    
    Madre::DB->do(
        q|INSERT into config(user_id,data)
            VALUES(?,?)|, {},
        session('user'), encode_json( \%payload )
    );
    
    status 204;
    
} ;

 #### 
 sub _SALT_PW {
     my ($nickname,$password) = @_;
     my $salt = substr( $nickname , 0, 1 ) . substr($nickname, -1,1);
     my $pw_hash = md5_hex( $salt  .  $password );    
     return $salt . ':' . $pw_hash;  
};



1;
