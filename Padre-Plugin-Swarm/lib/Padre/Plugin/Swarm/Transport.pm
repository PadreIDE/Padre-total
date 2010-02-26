package Padre::Plugin::Swarm::Transport;
use strict;
use warnings;
use Padre::Logger;
use JSON::PP;

sub new {
	my $class = shift;
	my %args = @_;
	$args{marshal} ||= $class->_marshal;
	bless \%args, $class;
}

sub plugin { Padre::Plugin::Swarm->instance }

sub loopback { 0 }

sub token { $_[0]->{token} }

sub send {
	my $self = shift;
	my $message = shift;
	$message->{token} ||= $self->token;
	my $data = eval { $self->marshal->encode( $message ) };
	if ($data) {
		$self->write($data);
		$self->on_recv->($message)
			if $self->on_recv && $self->loopback;
		TRACE( "Sent message " . $message->type ) if DEBUG;
	}
	else {
		TRACE( "Failed to encode message - $@" ) if DEBUG;
	}
	
}

sub _marshal {
	JSON::PP->new
	    ->allow_blessed
            ->convert_blessed
            ->utf8
            ->filter_json_object(\&synthetic_class );
}


sub synthetic_class {
	my $var = shift ;
	if ( exists $var->{__origin_class} ) {
		my $stub = $var->{__origin_class};
		my $msg_class = 'Padre::Swarm::Message::' . $stub;
		my $instance = bless $var , $msg_class;
		return $instance;
	} else {
		return bless $var , 'Padre::Swarm::Message';
	}
};

1;