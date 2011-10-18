#!/usr/bin/perl

use strict;
use warnings;
use Perl::Tidy ();

my $filename = '../wx-scintilla/src/scintilla/include/Scintilla.iface';
my $constants_filename = '../lib/Wx/Scintilla/Constants.pm';

print "Parsing $filename\n";
open my $fh, $filename or die "Cannot open $filename\n";
my $docs = "=pod\n";
$docs .= "=head2 Constants\n";
my $source = <<'CODE';
use constant {
CODE
my $doc_comment = undef;
while ( my $line = <$fh> ) {
    if ( $line =~ /^\s*$/ ) {

        # Empty line separator
        $doc_comment = undef;
    }
    elsif ( $line =~ /^##/ ) {

        # ignore pure comments
    }
    elsif ( $line =~ /^(#.+?)$/ ) {

        # Store documentation comments
        $doc_comment .= "\t$1\n";
    }
    elsif ( $line =~ /^\s*val\s+(\w+)\s*=(.+?)\s*$/ ) {
        if ( defined $doc_comment ) {
            $source .= $doc_comment;
            $doc_comment =~ s/\s+#\s+//g;
            $docs .= "\n$doc_comment\n";
            $doc_comment = undef;
        }
        $source .= "\t$1 => $2,\n";
        $docs .= sprintf( "%-20s (%s)\n\n", $1, $2 );
    }
}
$docs   .= "=cut\n";
$source .= "};\n";
$source .= "\n\n$docs";
close $fh;
print "Perl tidy output in memory\n";
my $output = '';
Perl::Tidy::perltidy(
    source      => \$source,
    destination => \$output,
    argv        => '--indent-block-comments',
);

print "Writing to $constants_filename\n";
open my $constants_fh, '>', $constants_filename
  or die "Cannot open $constants_filename\n";
print $constants_fh $output;
close $constants_fh;
close $fh;
