use strict;
use warnings;

use Test::More;
my $tests;

plan tests => $tests;

use Padre::Plugin::PerlTidy;
use Padre;
diag "Padre::Plugin::PerlTidy: $Padre::Plugin::PerlTidy::VERSION";
diag "Padre: $Padre::VERSION";
diag "Wx Version: $Wx::VERSION " . Wx::wxVERSION_STRING();
 
{
    my @menu = Padre::Plugin::PerlTidy->menu_plugins_simple;
    is @menu, 2, 'one menu item';
    is $menu[0], 'PerlTidy', 'plugin name';

    # check for existence and not the actual words as these
    # are locale specific
    ok $menu[1][0], 'menu item 1'; 
    ok $menu[1][2], 'menu item 2';

    BEGIN { $tests += 4; }
}
