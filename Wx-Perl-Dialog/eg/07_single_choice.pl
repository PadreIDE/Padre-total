use strict;
use warnings;

use Wx        qw(:everything);
use Wx::Event qw(:everything);

use Wx::Perl::Dialog::SingleChoice;
print Wx::Perl::Dialog::SingleChoice::dialog( title => 'Select one', values => ['a'..'d'] ), "\n";

