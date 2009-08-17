use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../../lib";

use Padre::Plugin::SDL::Logoish;

my $logo = Padre::Plugin::SDL::Logoish->new;

$logo->goto_xy(10, 10);


sleep 2;

