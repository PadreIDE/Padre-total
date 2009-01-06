package Padre::Task::DocBrowser;
use strict;
use warnings;
use Padre::DocBrowser;
use threads;

use base 'Padre::Task';

use Data::Dumper;

sub run {
    my ($self) = @_;
warn sprintf( "THREAD (%d) RUNNING '%s' \n",
                threads->tid() ,   $self->{document} );

    $self->{browser} ||=  Padre::DocBrowser->new();
    my $type = $self->{type} || 'error';
    if ( $type eq 'error' ) {
        return "BREAK";
    }
    unless ( $self->{browser}->can( $type ) ) {
        return "BREAK";
    }

    my $result = $self->{browser}->$type( $self->{document} );
    $self->{result} = $result;
    return 1;
    
       
}

sub finish {
    my ($self,$mw) = @_;
    $self->{main_thread_only}->( $self->{result}, $self->{document} );
}

1;
