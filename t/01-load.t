use strict;
use warnings;

use Test::More;
my $tests;

plan tests => $tests;

use Padre::Plugin::PAR;
use Padre;
diag "Padre::Plugin::PAR: $Padre::Plugin::PAR::VERSION";
diag "Padre: $Padre::VERSION";
diag "Wx Version: $Wx::VERSION " . Wx::wxVERSION_STRING();
 
{
    my @menu = Padre::Plugin::PAR->menu;
    is @menu, 1, 'one menu item';
    is $menu[0][0], 'Stand alone', 'menu item';
    BEGIN { $tests += 2; }
}
