#!/usr/bin/perl

use 5.006;
use strict;
use warnings;
use Test::More tests => 6;
use Padre::Plugin::wxGlade ();
use PPI::Document          ();

# We need a fake IDE object to boot up the plugin
my $ide = bless {}, 'Padre';

# Create the plugin outside of a full Padre instance
my $plugin = Padre::Plugin::wxGlade->new( $ide );
isa_ok( $plugin, 'Padre::Plugin::wxGlade' );





######################################################################
# Processing content with nothing in it

SCOPE: {
	my $text = <<'END_PERL';
package Foo;

print;
END_PERL
	is(
		$plugin->normalise_constants($text),
		$text,
		'->normalise_constants(none) ok'
	);
}





######################################################################
# Process with a single known-good constant

SCOPE: {
	my $input    = "package Foo;\nprint wxRED;\n";
	my $output   = $plugin->normalise_constants($input);
	my $expected = "package Foo;\nprint Wx::wxRED;\n";
	is( $output, $expected, '->normalise_constants(one) ok' );
	$output = $plugin->normalise_constants($output);
	is( $output, $expected, '->normalise_constants(one) ok' );
}





######################################################################
# Process with a single known-good event

SCOPE: {
	my $input    = "package Foo;\nprint EVT_MAXIMIZE;\n";
	my $output   = $plugin->normalise_constants($input);
	my $expected = "package Foo;\nprint Wx::Event::EVT_MAXIMIZE;\n";
	is( $output, $expected, '->normalise_constants(one) ok' );
	$output = $plugin->normalise_constants($output);
	is( $output, $expected, '->normalise_constants(one) ok' );
}
