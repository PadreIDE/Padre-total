#
# This file is part of Padre::Plugin::Autoformat.
# Copyright (c) 2009 Jerome Quelin, all rights reserved.
#
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
#

use strict;
use warnings;

use Test::More tests => 1;

BEGIN {
    use_ok( 'Padre::Plugin::Autoformat' );
}
diag( "Testing Padre::Plugin::Autoformat $Padre::Plugin::Autoformat::VERSION, Perl $], $^X" );
