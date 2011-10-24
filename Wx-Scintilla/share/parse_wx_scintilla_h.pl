#!/usr/bin/perl

use strict;
use warnings;
use Perl::Tidy ();

my $filename = '../wx-scintilla/src/scintilla/include/Scintilla.iface';
my $constants_pm = '../lib/Wx/Scintilla/Constants.pm';
my $constants_pod = '../lib/Wx/Scintilla/Manual/Constants.pod',

my %lexers = (
    SCLEX_PYTHON     => 'Python',
    SCLEX_CPP        => 'C/C++/JavaScript',
    SCLEX_D          => 'D',
    SCLEX_TCL        => 'Tcl',
    SCLEX_HTML       => 'HTML & Embedded JavaScript/VBScript',
    SCLEX_PERL       => 'Perl',
    SCLEX_RUBY       => 'Ruby',
    SCLEX_VB         => 'Visual Basic',
    SCLEX_PROPERTIES => 'Properties',
    SCLEX_LATEX      => 'Latex',
    SCLEX_LUA        => 'Lua',
    SCLEX_ERRORLIST  => 'Error List',
    SCLEX_BATCH      => 'Batch',
    SCLEX_MAKEFILE   => 'Makefile',
    SCLEX_DIFF       => 'Diff',
    SCLEX_CONF       => 'Apache Conf',
    SCLEX_AVE        => 'Avenue',
    SCLEX_ADA        => 'Ada',
    SCLEX_BAAN       => 'Baan',
    SCLEX_LISP       => 'Lisp',
    SCLEX_EIFFEL     => 'Eiffel',
    SCLEX_NNCRONTAB  => 'crontab',
    SCLEX_FORTH      => 'Forth',
    SCLEX_MATLAB     => 'Matlab',
    SCLEX_SCRIPTOL   => 'Scriptol',
    SCLEX_ASM        => 'Assembly',
    SCLEX_FORTRAN    => 'Fortran',
    SCLEX_CSS        => 'CSS',
    SCLEX_POV        => 'Povray',
    SCLEX_LOUT       => 'Lout',
    SCLEX_ESCRIPT    => 'Escript',
    SCLEX_PS         => 'Postscript',
    SCLEX_NSIS       => 'NSIS',
    SCLEX_MMIXAL     => 'MMIXAL',
    SCLEX_CLW        => 'CLW',
    SCLEX_LOT        => 'LOT',
    SCLEX_YAML       => 'YAML',
    SCLEX_TEX        => 'TeX',
    SCLEX_ERLANG     => 'Erlang',
    SCLEX_OCTAVE     => 'Octave',
    SCLEX_MSSQL      => 'MSSQL',
    SCLEX_VERILOG    => 'Verilog',
    SCLEX_KIX        => 'KIX',
    SCLEX_GUI4CLI    => 'GUI4CLU',
    SCLEX_SPECMAN    => 'Specman',
    SCLEX_AU3        => 'Au3',
    SCLEX_APDL       => 'APDL',
    SCLEX_BASH       => 'Bash',
    SCLEX_ASN1       => 'Asn1',
    SCLEX_VHDL       => 'VHDL',
    SCLEX_CAML       => 'CAML',
    SCLEX_HASKELL    => 'Haskell',
    SCLEX_REBOL      => 'Rebol',
    SCLEX_SQL        => 'SQL',
    SCLEX_SMALLTALK  => 'Smalltalk',
    SCLEX_FLAGSHIP   => 'Flagship',
    SCLEX_CSOUND     => 'CSound',
    SCLEX_INNOSETUP  => 'InnoSetup',
    SCLEX_OPAL       => 'Opal',
    SCLEX_SPICE      => 'Spice',
    SCLEX_CMAKE      => 'Cmake',
    SCLEX_GAP        => 'Gap',
    SCLEX_ABAQUS     => 'Abaqus',
    SCLEX_ASYMPTOTE  => 'Asymptote',
    SCLEX_R          => 'R',
    SCLEX_PASCAL     => 'Pascal',
    SCLEX_SML        => 'SML',
    SCLEX_A68K       => 'A68K',
    SCLEX_MODULA     => 'Modula',
);

print "Parsing $filename\n";
open my $fh, $filename or die "Cannot open $filename\n";
my $docs = '';
my $source = <<'CODE';
use constant {
CODE
my $doc_comment = undef;
my $pod = '';
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
        my $comment = $1;
        if ( $comment =~ /Lexical states for (\w+)/ ) {
            
            my $name = $lexers{$1};
            if ( $name ) {
                $pod .= "\n=head2 $name ($1) lexical states\n";
            }
            else {
                die  "Cannot find $1 in \%lexers\n";
            }

        }
        else {
            $comment =~ s/^#\s*//;
            $pod .= "\t$comment\n";
        }
        $doc_comment .= "\t$comment\n";

    }
    elsif ( $line =~ /^\s*enu\s+(\w+)\s*=\s*(\w+)\s*$/ ) {

        # Enumeration
        $doc_comment = "$1 enumeration\n";
        $pod .= "\n=head2 $1 enumeration\n";
    }
    elsif ( $line =~ /^\s*val\s+(\w+)\s*=(.+?)\s*$/ ) {
        if ( defined $doc_comment ) {
            $source .= $doc_comment;
            $doc_comment =~ s/\s+#\s+//g;
            $docs .= "\n$doc_comment\n";
            $pod .= "\n$doc_comment\n";
            $doc_comment = undef;
        }
        $source .= "\t$1 => $2,\n";
        $docs .= sprintf( "%-20s (%s)\n\n", $1, $2 );
        $pod .= sprintf( "%-20s (%s)\n\n", $1, $2 );
    }
}
$source .= "};\n";
close $fh;


open $fh, '>', $constants_pod or die "Cannot write to $constants_pod\n";
binmode $fh;
print $fh <<"POD";
package Wx::Scintilla::Manual;

=pod

=head1 NAME

Wx::Scintilla::Manual::Constants - A list of Wx::Scintilla constants

=head1 CONSTANTS

$pod

=head1 AUTHOR

Ahmad M. Zawawi <ahmad.zawawi\@gmail.com>

=head1 COPYRIGHT

Copyright 2011 Ahmad M. Zawawi.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

=cut
POD
close $fh;

print "Perl tidy output in memory\n";
my $output = '';
Perl::Tidy::perltidy(
    source      => \$source,
    destination => \$output,
    argv        => '--indent-block-comments',
);

print "Writing to $constants_pm\n";
open my $constants_fh, '>', $constants_pm
  or die "Cannot open $constants_pm\n";
binmode $constants_fh;
print $constants_fh $output;
close $constants_fh;
