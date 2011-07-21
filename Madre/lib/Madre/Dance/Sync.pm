package Madre::Dance::Sync;
use Dancer;
use Madre::DB;
use Digest::MD5 'md5_hex';
use Data::Dumper;

set serializer => 'mutable';

prefix '/user';

# get '/id/*' => sub {
    # my ($userid) = splat;
    # my $user = Madre::DB::User->load( $userid );
    # return $user;
# };

get '/name/*' => sub {
    my ($username) = splat;
    my $users = Madre::DB::User->select( 'where username = ? ',$username );
    # Single row.
    if ( @$users == 1 ) {
        return $users->[0];
    } else {
        die "Unexpected multirow select for username '$username'";
    }
};

get '/register' => sub {
    return template 'register.tt', { title=>'Registration' } ;
    
};

post '/register' => sub {
    my $nickname        = params->{nickname};
    my $password        = params->{password};
    my $password_confirm= params->{password_confirm};
    
    my $email           = params->{email};
    my $email_confirm   = params->{email_confirm};
    
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
            #warn "ERROR $@";
            return template 'register.tt', { error=>$@, title=>'Registration' };
        }
        
    }

    my $salt = substr( $nickname , 0, 1 ) . substr($nickname, -1,1);
    my $pw_hash = md5_hex( $salt . ':' . $password );
    
    
    
    my $user = eval { 
            Madre::DB::User->create( 
                username => $nickname,
                password => $pw_hash,
                email    => $email,
            );
        };
    
    if ($@ or ! defined $user) {
        status 500; # Internal error
        return "$@";
    } else {
        my $location = '/user/name/' . $nickname;
        status 201; # Created
        header 'Location' => $location;
        return template 'created.tt' , { user=>$user, user_uri => $location };
    }


};


1;
