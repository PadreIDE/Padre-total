package Padre::Swarm::Callback;
use strict;
use warnings;
use vars '$AUTOLOAD';

SCOPE: {
	my %callbacks = ();
	my $id = 0;
  sub GENERATE {
	my ($instance,@args) = @_;
	my $signature = $id++;
	$callbacks{$signature} = [$instance,\@args];
	return bless \$signature, __PACKAGE__;
  }

  sub DESTROY {
	my $self = shift;
	delete $callbacks{$$self};
	
  }


  sub AUTOLOAD {
	my $self = shift;
	my $cb = $callbacks{$$self};
	my ($instance,$args) = @$cb;
	my $name = $AUTOLOAD;
	$name =~ s/.*://;   # strip fully-qualified portion

	my $callback = sub {
	    $instance->$name( @$args ) 
	
	}; 
        warn "Curried call on $instance -> $name";
        return $callback;
        
  }

} # SCOPE


1;
