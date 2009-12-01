#!/usr/bin/perl

# Tests for the WXG object

use 5.006;
use strict;
use warnings;
use Test::More 0.82 tests => 19;
use File::Spec::Functions ':ALL';
use Padre::Plugin::wxGlade::WXG ();

my $SAMPLE = catfile( 't', 'sample', 'Dialogs.wxg' );
ok( -f $SAMPLE, 'Sample wxg file exists' );

my @WINDOWS = qw{
	frame_1
	dialog_find
	dialog_replace
	dialog_openurl
	dialog_warning
};	





######################################################################
# Load the Object

my $wxg = new_ok(
	'Padre::Plugin::wxGlade::WXG' => [ $SAMPLE ],
	"Loaded $SAMPLE",
);

# Accessor tests
is( $wxg->wxg,         $SAMPLE, '->file ok'        );
is( $wxg->language,    'perl',  '->language ok'    );
is( $wxg->for_version, '2.8',   '->for_version ok' );
is( $wxg->path, 'F:\padre\Padre-Plugin-wxGlade\t\sample\Dialogs.pl', '->path ok' );

# Get the list of windows
my @windows = $wxg->windows;
is_deeply(
	\@windows,
	\@WINDOWS,
	'Found expected windows',
);

# Load a named window
is( ref($wxg->window('dialog_warning')), 'HASH', 'Found dialog_warning' );
is( ref($wxg->top_window), 'HASH', 'Found ->top_window' );

# Extract the Perl class for each
foreach my $name ( @WINDOWS ) {
	my $code = $wxg->extract( $wxg->window($name) );
	ok( defined $code, 'Found code for $name' );
	ok( length($code), 'Found code for $name' );
}

1;
