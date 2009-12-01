#!/usr/bin/perl

use 5.006;
use strict;
use warnings;
use Test::More 0.82 tests => 3;

use_ok( 'Padre::Wx'                   );
use_ok( 'Padre::Plugin::wxGlade'      );
use_ok( 'Padre::Plugin::wxGlade::WXG' );
