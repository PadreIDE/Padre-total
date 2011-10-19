package ExSewi;

use 5.010;
use strict;
use warnings;

our $VERSION = '0.01';

use base 'Exporter';
our @EXPORT_OK = qw(wh eh); 



sub wh {
	
	my $fred = 'bloggs';
	
	#bp 19-20 this is 18
	say 'running wh';
	say $_[0];
	return; 
}

sub eh {
	my $fred = $_[0];
	$_[0] = 'not fred';
	say $fred;
	return;
}

1;
