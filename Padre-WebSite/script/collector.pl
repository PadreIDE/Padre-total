#!/usr/bin/perl
use strict;
use warnings;

use CGI;
use DBI;
use YAML::Tiny;

main();

sub main {
	my $q = CGI->new;
	print $q->header;
	
	my $host_id = $q->param('hostid');
	my $data    = $q->param('data');
}

