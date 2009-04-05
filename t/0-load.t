#
# This file is part of Padre::Plugin::SpellCheck.
# Copyright (c) 2009 Fayland Lam, all rights reserved.
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
    use_ok( 'Padre::Plugin::SpellCheck' );
}

diag( "Testing Padre::Plugin::SpellCheck $Padre::Plugin::SpellCheck::VERSION, Perl $], $^X" );
