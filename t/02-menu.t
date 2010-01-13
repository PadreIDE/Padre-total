use strict;
use warnings;

use Test::More tests => 4;

use Padre::Plugin::PerlTidy;

{
    my @menu = Padre::Plugin::PerlTidy->menu_plugins_simple;
    is @menu, 2, 'one menu item';
    is $menu[0], 'Perl Tidy', 'plugin name';

    # check for existence and not the actual words as these
    # are locale specific
    ok $menu[1][0], 'menu item 1'; 
    ok $menu[1][2], 'menu item 2';
}
