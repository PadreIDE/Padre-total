use strict;
use warnings;

use Test::More;
my $tests;

plan tests => 3;

use Padre::Plugin::PerlCritic;
use Padre;
diag "Padre::Plugin::PerlCritic: $Padre::Plugin::PerlCritic::VERSION";
diag "Padre: $Padre::VERSION";
diag "Wx Version: $Wx::VERSION " . Wx::wxVERSION_STRING();
{
    my @menu = Padre::Plugin::PerlCritic->menu_plugins_simple;
    is @menu, 2, 'one menu item';
    is $menu[0], 'PerlCritic', 'Plugin name';
    is $menu[1]->[0], 'Run PerlCritic', 'Menu item 1, Run PerlCritic';
}
