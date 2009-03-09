package Padre::Document::PHP;

use 5.008;
use strict;
use warnings;
use Carp            ();
use Padre::Document ();

our $VERSION = '0.01';
our @ISA     = 'Padre::Document';

sub comment_lines_str { return '#' }

1;
