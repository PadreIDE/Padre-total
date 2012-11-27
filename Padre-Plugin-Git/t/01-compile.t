#!/usr/bin/perl

use strict;
use Test::More tests => 12;

use_ok('Padre::Plugin::Git');

# Check dependencies that are not checked but Padre::Plugin::Git.pm itself
BEGIN {
	use_ok( 'CPAN::Changes', '0.19' );
	use_ok( 'Carp',          '1.26' );
	use_ok( 'Data::Printer', '0.33' );
	use_ok( 'File::Slurp',   '1.09' );
	use_ok( 'File::Spec',    '1.09' );
	use_ok( 'File::Which',   '1.09' );
	use_ok( 'Padre',         '0.96' );
	use_ok( 'Pithub',        '0.01016' );
	use_ok( 'Try::Tiny',     '0.11' );
	use_ok( 'Test::More',    '0.98' );
	use_ok( 'Test::Deep',    '0.108' );
}

diag("Info: Testing Padre::Plugin::Git $Padre::Plugin::Git::VERSION");

done_testing();

1;

__END__

