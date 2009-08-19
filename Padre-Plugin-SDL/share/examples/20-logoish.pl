use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../../lib";

use Padre::Plugin::SDL::Logoish;

my $logo = Padre::Plugin::SDL::Logoish->new;

$logo->goto_xy(10, 10);
#$logo->wait(1);
$logo->goto_xy(10, 100);
$logo->goto_xy(100, 100);
$logo->wait(1);
$logo->clear;
$logo->goto_xy(200, 100);
$logo->wait(2);
