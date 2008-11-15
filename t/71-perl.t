#!/usr/bin/perl

use strict;
use warnings;
use Test::NeedsDisplay;
use Test::More;
use File::Spec  ();
use t::lib::Padre;
use t::lib::Padre::Editor;

my $tests;
plan tests => $tests;

use Padre::Document;
use Padre::PPI;

my $editor_1 = t::lib::Padre::Editor->new;
my $file_1   = File::Spec->catfile('t', 'files', 'missing_brace_1.pl');
my $doc_1    = Padre::Document->new(
	editor    => $editor_1, 
	filename  => $file_1,
);

SCOPE: {
	isa_ok($doc_1, 'Padre::Document');
	isa_ok($doc_1, 'Padre::Document::Perl');
	is($doc_1->filename, $file_1, 'filename');
	
	#Padre::PPI::find_unmatched_brace();
    BEGIN { $tests += 3; }
}

