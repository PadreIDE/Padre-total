package Padre::Plugin::Swarm::Transport;
use strict;
use warnings;

use JSON::PP;


sub new {
	my $class = shift;
	my %args = @_;
	$args{marshal} ||= $class->_marshal;
	return $class->SUPER::new(%args);
}


sub plugin { Padre::Plugin::Swarm->instance }

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