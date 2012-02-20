package Madre::DB::User;

use 5.008;
use strict;
use Madre::DB ();

our $VERSION = '0.1';

sub new {
    my $class = shift;
    my $self  = $class->SUPER::new(@_);

    # Default the created value
    unless ( defined $self->{created} ) {
        $self->{created} = Madre::DB->datetime;
    }

    return $self;
}

1;
