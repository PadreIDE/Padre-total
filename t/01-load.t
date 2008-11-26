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
    is $menu[1][0], 'Tidy the active document', 'menu item 1';
    is $menu[1][2], 'Tidy the selected text', 'menu item 2';
    BEGIN { $tests += 4; }
}
