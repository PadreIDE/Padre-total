#!/usr/bin/perl

use strict;
use warnings;
use Test::NeedsDisplay;
use Test::More;
use t::lib::Padre;
use t::lib::Padre::Editor;

my $tests;
plan tests => $tests;

use Padre::Document;

my $editor = t::lib::Padre::Editor->new;
my $d = Padre::Document->new(editor => $editor);


SCOPE: {
	isa_ok($d, 'Padre::Document');
    BEGIN { $tests += 1; }
}

