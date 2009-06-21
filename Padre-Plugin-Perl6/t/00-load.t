use strict;
use warnings;

use Test::More tests => 1; 

BEGIN {
	if (not $ENV{DISPLAY} and not $^O eq 'MSWin32') {
		plan skip_all => 'Needs DISPLAY';
		exit 0;
	}
}

BEGIN {
	use_ok('Padre::Plugin::Perl6');
}



