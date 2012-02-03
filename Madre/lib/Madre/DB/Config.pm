package Madre::DB::Config;

use 5.008;
use strict;
use Madre::DB ();

our $VERSION = '0.01';

sub new {
    my $class = shift;
    my $self  = $class->SUPER::new(@_);

    # Default the modified value
    unless ( defined $self->{modified} ) {
        $self->{modified} = Madre::DB->datetime;
    }

    return $self;
}

1;
