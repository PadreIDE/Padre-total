package Vimper::Types;

use 5.010;
use Moose;
use Moose::Autobox;
use MooseX::Types::Moose qw(Str Int ArrayRef Bool);
use MooseX::Types -declare, [qw(
    StrList SheetBool SheetTriState
)];

# common types

subtype StrList, as ArrayRef;
coerce StrList, from Str, via { $_->split(qr/ /) };

subtype SheetBool, as Bool;
coerce SheetBool, from Str, via { $_ ~~ /●/? 1:
                                  $_ ~~ /◌/? 0:
                                  die "SheetBool: $_" };

subtype SheetTriState, as Int, where { $_ >= 0 and $_ <= 2 };
coerce SheetTriState, from Str, via { $_ ~~ /█/? 2:
                                      $_ ~~ /●/? 1:
                                      $_ ~~ /◌/? 0:
                                      die "SheetTriState: $_" };

1;
