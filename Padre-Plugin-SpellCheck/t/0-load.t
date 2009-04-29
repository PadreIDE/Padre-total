#
# This file is part of Padre::Plugin::SpellCheck.
# Copyright (c) 2009 Jerome Quelin, all rights reserved.
#
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
#

use strict;
use warnings;

use Test::More tests => 3;

BEGIN {
    use_ok( 'Padre::Plugin::SpellCheck' );
    use_ok( 'Padre::Plugin::SpellCheck::Dialog' );
    use_ok( 'Padre::Plugin::SpellCheck::Engine' );
}

diag( "Testing Padre::Plugin::SpellCheck $Padre::Plugin::SpellCheck::VERSION, Perl $], $^X" );
