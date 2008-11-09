#!/usr/bin/perl

use strict;
use warnings;
use Test::NeedsDisplay;
use Test::More;
use t::lib::Padre;

my $tests;
plan tests => $tests;

use Padre::Document;

my $editor = Padre::Editor->new;
my $d = Padre::Document->new(editor => $editor);


SCOPE: {
	isa_ok($d, 'Padre::Document');
    BEGIN { $tests += 1; }
}

package Padre::Editor;
use strict;
use warnings;

sub new {
	return bless {}, shift;
}

sub SetEOLMode {
}

sub SetText {
	$_[0]->{text} = $_[1];
}

sub EmptyUndoBuffer {
}

#sub ConvertEOLs {
#}
