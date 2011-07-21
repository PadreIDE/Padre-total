package Madre::Dance::Sync;
use Dancer;
use Madre::DB;
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
    return template 'register.tt' , { error => param 'error' };
    
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
            } elsif ( ! defined $password ) {
                die "You must supply a password\n";
            } elsif ( ! defined $email ) {
                die "You must supply an email address\n";
            }
        };
        
        if ($@) {
            #warn "ERROR $@";
            return forward '/user/register',{error=>$@},{method=>'GET'};
        }
        
    }

    my ($salt,$pw) = $password =~ m/^([A-Za-z0-9]{2}):([A-Fa-f0-9]+)$/;
    unless ( $salt and $pw and length($pw) >= 32 ) {
        status 422; # Unprocessable
        return 'password salt:hex_digest required';
    }
    
    my $crypted_password = Madre->crypt( $password );
    
    my $user = eval { 
            Madre::DB::User->create( 
                username => $nickname,
                password => $crypted_password,
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
        return;
    }


};


1;
