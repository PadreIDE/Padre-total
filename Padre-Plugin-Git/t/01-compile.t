#!/usr/bin/perl

use strict;
use Test::More tests => 6;

use_ok('Padre::Plugin::Git');

# Check dependencies that are not checked but Padre::Plugin::Git.pm itself
BEGIN { use_ok( 'File::Which', '1.09' ) };
BEGIN { use_ok( 'Try::Tiny', '0.11' ) };
BEGIN { use_ok( 'Pithub', '0.01014' ) };

BEGIN { use_ok( 'Test::More', '0.98' ) };
BEGIN { use_ok( 'Test::Deep', '0.108' ) };


diag("Info: Testing Padre::Plugin::Git $Padre::Plugin::Git::VERSION");

done_testing();

1;

__END__

