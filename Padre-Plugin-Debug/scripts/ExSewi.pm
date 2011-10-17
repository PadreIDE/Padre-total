package ExSewi;

use 5.010;
use strict;
use warnings;

our $VERSION = '0.01';

use base 'Exporter';
our @EXPORT_OK = qw(wh eh); 

sub wh {
	#bp 14 & 15 this is 13
	say 'running wh';
	say $_[0];
	return; 
}

sub eh {
	return;
}

1;
