package Padre::Plugin::Swarm::Resource;
use strict;
use warnings;
use Time::HiRes 'time';
use Digest::JHash 'jhash';

use Class::XSAccessor 
    accessors => [qw(
        zerotime
        zerohash
        sequence
        body
        project
        path
    )];
    
my $MAX_HISTORY = 200;

sub new {
    my ($class,@args) = @_;
    my $self = bless {@args} , ref($class)||$class;
    $self->zerotime( time() );
    $self->zerohash( jhash($self->body) );
    
    
    return $self;
}


sub perform_edit {
    my ($self,$edit) = @_;
    my $dtime = time() - $self->zerotime;
    my $sequence = $self->sequence;
    $sequence++;
    
    
}

sub perform_remote_edit {
    my ($self,$edit) = @_;
    my $r_zerotime = $edit->zerotime;
    
}


1;
