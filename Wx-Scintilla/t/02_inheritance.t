#!/usr/bin/perl -w

use strict;
use Wx;
use lib "t/lib";
use Test::More 'no_plan';
use Tests_Helper qw(:inheritance);

BEGIN { test_inheritance_start() }
use Wx::Scintilla;
test_inheritance_end();
