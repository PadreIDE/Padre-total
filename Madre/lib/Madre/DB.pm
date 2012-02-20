package Madre::DB;

use 5.008;
use strict;
use File::Spec                 ();
use DateTime                   ();
use DateTime::Format::Strptime ();

our $VERSION = '0.01';

our $FILE;
BEGIN {
    $FILE ||= 'data/madre.db';
}

use ORLite::Migrate 1.10 {
    file         => $FILE,
    timeline     => 'Madre::Timeline',
    user_version => 3,
    shim         => 1,
};

my $DATEFORMAT = DateTime::Format::Strptime->new(
    pattern => '%F %T %z',
);

sub datetime {
    my $class = shift;
    my $value = shift || DateTime->now;
    $DATEFORMAT->format_datetime($value);
}

1;
