#!perl
use 5.010;
use utf8;
use strict;
use warnings FATAL => 'all';
use autodie qw(:all);
use Capture::Tiny qw(capture);
use Encode qw(decode_utf8);
use File::Next qw();
use File::Temp qw(tempfile);
use File::Which qw(which);
use Test::More;
use XML::LibXML qw();
use XML::LibXSLT qw();

# Skip means sweep bugs under the rug.
# I want this test to be actually run.
BAIL_OUT 'aspell is not installed.' unless which 'aspell';

my @stopwords;
for (<DATA>) {
    chomp;
    push @stopwords, $_ unless /\A (?: \# | \s* \z)/msx;    # skip comments, whitespace
}

my $destdir;
{
    my $runtime_params_file = '_build/runtime_params';
    my $runtime_params      = do $runtime_params_file;
    die "Could not load $runtime_params_file. Run Build.PL first.\n"
      unless $runtime_params;
    $destdir = $runtime_params->{destdir};
}

my $iter = File::Next::files({
        file_filter => sub {/\.html \z/msx},
        sort_files  => 1,
    },
    $destdir
);

my $file_counter;

my $stylesheet = XML::LibXSLT->new->parse_stylesheet(
    XML::LibXML->load_xml(string => <<''));
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xhtml="http://www.w3.org/1999/xhtml" version="1.0">
    <xsl:template match="xhtml:*[@xml:lang!='en']"/> <!-- filter non-English -->
    <xsl:template match="xhtml:pre"/> <!-- filter computerese -->
    <xsl:template match="xhtml:code"/>
    <xsl:template match="xhtml:cite"/>
    <xsl:template match="xhtml:title"/>
    <xsl:template match="xhtml:abbr"/>
    <xsl:template match="xhtml:acronym"/>
    <xsl:template match="@* | node()"> <!-- apply identity function to rest of nodes -->
        <xsl:copy>
            <xsl:apply-templates select="@* | node()"/>
        </xsl:copy>
    </xsl:template>
</xsl:stylesheet>

while (defined(my $html_file = $iter->())) {
    $file_counter++;

    my ($temp_handle, $temp_file) = tempfile;
    my $transformed = $stylesheet->transform(XML::LibXML->load_xml(location => $html_file));
    $stylesheet->output_fh($transformed, $temp_handle);

    my ($stdout) = capture {
        system "aspell -H --encoding=UTF-8 -l en list < $temp_file";
    };
    my @misspelt_words = grep {!($_ ~~ @stopwords)} split /\n/, decode_utf8 $stdout;
    ok !@misspelt_words, "$html_file ($temp_file) spell-check";
    diag join "\n", sort @misspelt_words if @misspelt_words;
}

done_testing($file_counter);

__DATA__
## personal names
ADAMK
Aharoni
Alguacil
Amir
AZAWAWI
Barbon
Barbon
barlog
# Joshua ben Jore
ben
Blandino
BlueT
Breno
Breunung
BRICAS
Cassidy
Cezary
CHRISDOLAN
CORION
ddn
# Breno G. de Oliveira
de
Dolan
Donelan
draegtun
ENELL
Fahle
Fayland
FAYLAND
Gábor
Gábor's
GABRIELMAD
garu
GARU
GYU
Haryanto
Heiko
HJANSEN
Ishigaki
ISHIGAKI
Jérôme
Jore
JQUELIN
Kaare
KAARE
Keedi
KEEDI
Kenichi
Kephra
Kjetil
KJETIL
lang
Maischein
Makholm
Mašláňová
Mattia
Mattia
Maurer
Miyagawa
mmaslano
Morga
Müller
Murias
Naim
Niebur
Nijs
Oliveira
Omer
PacoLinux
PATSPAM
Pawe
Petar
PMURIAS
Presta
PSHANGOV
Quelin
Rasnita
RSN
Ruslan
SBLANDIN
SEWI
Shafiev
Shangov
Shitov
Shlomi
SHLOMIF
Skotheim
Stevan
SZABGAB
Szabó
Tatsuhiko
TEEJAY
THEREK
Trevena
tsee
TSEE
tsee's
Vieira
wala
Zakirov
Zawawi

## proper names
ActivePerl
asciiville
Autodia
Debian
Dreamwidth
FreeBSD
Google
gvim
IRC
JSAN
KDE
KinoSearch
LiveJournal
MacOS
Mandriva
Mibbit
Mojo
Mojolicious
MSI
ORLite
ORLite's
PerlMonks
PDX
PGE
PHP
Rakudo
SQL
SQLite
SVN
TPF
Trac
Ubuntu
Ultraedit
WebGUI
Wx
wxPerl
wxPywiki
wxWidgets
YAML
YAPC
Zenity

## Padre-specific

## computerese
accessor
Accessor
accessors
Accessors
API
committer
deserializes
getters
IDE
inode
metadata
mutator
namespace
ORM
prepender
refactor
Refactor
refactoring
Refactoring
reflow
runtime
timestamp
Uncomment
uninstall

## other jargon

## neologisms
cloudfiguration
hackathon
Netbook
neurodiversity
Perliverse
screencast
screencasts
technopeasant

## compound
# July 27th
th
# multi-lingual and multi-technology
multi
# Multi-line
Multi
# vice-versa
versa

## slang
Grr

## things that should be in the dictionary, but are not
blog
bloggers
blogs
Blogs
crafters
executables
natively
pragma
pragmas
screenshot
screenshots
Screenshots
subdirectory
Subdirectory
versioned
wiki

## single foreign words
hijab
kippah

## misspelt on purpose
