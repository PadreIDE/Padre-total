use strict;
use warnings;

my $filename     = '../wx-scintilla/include/WxScintilla.h';
my $out_filename = '../lib/Wx/Scintilla/Constants.pm';

open my $fh, $filename
  or die "Cannot open $filename\n";
open my $output, '>', $out_filename
  or die "Cannot open $out_filename\n";
print $output <<'CODE';
package Wx::Scintilla::Constants;

use constant {
CODE

while ( my $line = <$fh> ) {
    if ( $line =~ /^\s*#define\s+wxSTC_(.+)\s+(.+)\s*$/ ) {

        my ( $name, $val ) = ( $1, $2 );
        $name =~ s/^(\d)/_$1/;
        print $output "$name => $val,\n";
    }
}
print $output "};\n";
close $output;
close $fh;
