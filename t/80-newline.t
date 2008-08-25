#!/usr/bin/perl
use strict;
use warnings;

my $CR   = "\015";
my $LF   = "\012";
my $CRLF = "\015\012";

use Test::More;
my $tests;

use Padre;

plan tests => $tests;


{
    is(Padre::get_newline_type("...") => "None", "None");
    is(Padre::get_newline_type(".$CR.$CR.") => "Mac", "Mac");
    is(Padre::get_newline_type(".$LF.$LF.") => "UNIX", "Unix");
    is(Padre::get_newline_type(".$CRLF.$CRLF.") => "Windows", "Windows");
    BEGIN { $tests += 4; }
}

{
    is(Padre::get_newline_type(".$LF.$CR.") => "Mixed", "Mixed");
    is(Padre::get_newline_type(".$CR.$LF.") => "Mixed", "Mixed");
    is(Padre::get_newline_type(".$CRLF.$LF.") => "Mixed", "Mixed");
    is(Padre::get_newline_type(".$LF.$CRLF.") => "Mixed", "Mixed");
    is(Padre::get_newline_type(".$CR.$CRLF.") => "Mixed", "Mixed");
    is(Padre::get_newline_type(".$CRLF.$CR.") => "Mixed", "Mixed");

    is(Padre::get_newline_type(".$CR$LF$CR.") => "Mixed", "Mixed");
    is(Padre::get_newline_type(".$CR$LF$LF.") => "Mixed", "Mixed");

    BEGIN { $tests += 8; }
}

