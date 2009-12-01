#!/usr/bin/perl

# Tests for the WXG object

use 5.006;
use strict;
use warnings;
use Test::More 0.82 tests => 2;
use File::Spec::Functions ':ALL';
use Padre::Plugin::wxGlade::WXG ();

my $SAMPLE = catfile( 't', 'sample', 'Dialogs.wxg' );
ok( -f $SAMPLE, 'Sample wxg file exists' );





######################################################################
# Load the Object

my $wxg = new_ok(
	'Padre::Plugin::wxGlade::WXG' => [ $SAMPLE ],
	"Loaded $SAMPLE",
);

1;
