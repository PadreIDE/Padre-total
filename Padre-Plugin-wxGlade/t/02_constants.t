#!/usr/bin/perl

use 5.006;
use strict;
use warnings;
use Test::More tests => 7;
use Padre::Plugin::wxGlade ();
use PPI::Document          ();

# We need a fake IDE object to boot up the plugin
my $ide = bless {}, 'Padre';

# Create the plugin outside of a full Padre instance
my $plugin = Padre::Plugin::wxGlade->new( $ide );
isa_ok( $plugin, 'Padre::Plugin::wxGlade' );

# Get the list of installed constants
my $hash = $plugin->constant_mapping;
is( ref($hash), 'HASH', '->constant_mapping returns a HASH' );





######################################################################
# Processing content with nothing in it

SCOPE: {
	my $doc = PPI::Document->new( \<<'END_PERL' );
package Foo;

print;
END_PERL
	isa_ok( $doc, 'PPI::Document' );
	is(
		$plugin->constant_normalise($doc), 0,
		'->constant_normalise(none) ok'
	);
}





######################################################################
# Process with a single known-good constant

SCOPE: {
	my $doc = PPI::Document->new( \<<'END_PERL' );
package Foo;
print wxRED;
END_PERL
	isa_ok( $doc, 'PPI::Document' );
	is(
		$plugin->constant_normalise($doc), 1,
		'->constant_normalise(one) ok'
	);
	is( $doc->serialize, <<'END_PERL', 'Converted ok' );
package Foo;
print Wx::wxRED;
END_PERL
}
