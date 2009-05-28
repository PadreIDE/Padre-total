package MyServer;

use strict;
use warnings;
use base qw(HTTP::Server::Simple::CGI);

sub handle_request {
	my ($self, $cgi) = @_;

	print "Hello World";

	return;
}

1;
