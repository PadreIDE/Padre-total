use strict;
use warnings;

use Test::More;

unless($ENV{AUTHOR_TEST}) {
	plan skip_all => 'Author test';
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
	my $f = File::Spec->catfile('blib/lib/auto/share/dist/Padre-Plugin-Perl6/locale', $file);
	is(-e $f, 1, "$f exists\n");
}
