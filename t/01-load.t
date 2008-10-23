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
    my @menu = Padre::Plugin::PerlTidy->menu;
    is @menu, 1, 'one menu item';
    is $menu[0][0], 'Perl Tidy', 'menu item';
    BEGIN { $tests += 2; }
}
