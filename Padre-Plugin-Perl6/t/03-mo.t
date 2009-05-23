use strict;
use warnings;

use Test::More;

unless($ENV{PADRE_PLUGIN_PERL6}) {
	plan skip_all => 'Needs PADRE_PLUGIN_PERL6 environment variable.';
}

my @files = (
	'Perl6-ar.mo',
	'Perl6-fr-fr.mo',
	'Perl6-nl-nl.mo',
	'Perl6-pl.mo',
	'Perl6-zh-tw.mo');

plan tests => scalar @files;
require File::Spec;
foreach my $file ( @files ) {
	my $f = File::Spec->catfile('blib/lib/Padre/Plugin/Perl6/share/locale', $file);
	is(-e $f, 1, "$f exists\n");
}
