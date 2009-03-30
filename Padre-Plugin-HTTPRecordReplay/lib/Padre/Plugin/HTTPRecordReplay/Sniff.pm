package Padre::Plugin::HTTPRecordReplay::Sniff;

use 5.008;
use strict;
use warnings;

use base 'Exporter';
our @EXPORT = qw(sniff);

# Currently lots of things are hard-coded here as this 
# is very experimental code


#print "UID: $< EUID: $>\n";
#use Data::Dumper;
#print  Dumper \@INC;

#__END__
use Sniffer::HTTP;
my $VERBOSE = 1;

#print Net::Pcap::FindDevice::interfaces_from_ip('127.0.0.1');

#__END__
sub sniff {
	my $sniffer = Sniffer::HTTP->new(
		callbacks => {
			request  => sub { my ($req,$conn) = @_; print $req->uri,"\n" if $req },
			response => sub { my ($res,$req,$conn) = @_; print $res->code,"\n" },
			log      => sub { print $_[0] if $VERBOSE },
			tcp_log  => sub { print $_[0] if $VERBOSE > 1 },
		},
		timeout => 5*60, # seconds after which a connection is considered stale
		stale_connection => sub { 
				my ($s,$conn,$key);
				$s->log->("Connection $key is stale.");
				$s->remove_connection($key);
			},
	);

	#$sniffer->run('lo'); # uses the "best" default device
	$sniffer->run('eth0'); # uses the "best" default device
}

1;

# Copyright 2008-2009 The Padre development team as listed in Padre.pm.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.
