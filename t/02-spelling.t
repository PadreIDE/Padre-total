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
barlog
# Joshua ben Jore
ben
Breno
Cassidy
Cezary
# Breno G. de Oliveira
de
Donelan
draegtun
Fahle
Fayland
Gábor
Gábor's
garu
Haryanto
Ishigaki
Jérôme
Jore
Kenichi
lang
Makholm
Mašláňová
Maurer
Morga
Müller
Naim
Niebur
Oliveira
Quelin
Presta
Ruslan
SEWI
Shafiev
Shitov
Shlomi
Stevan
Szabó
TEEJAY
Trevena
tsee
tsee's
wala
Zakirov
Zawawi

## proper names
ActivePerl
asciiville
Debian
Dreamwidth
FreeBSD
Google
gvim
JSAN
KinoSearch
LiveJournal
MacOS
Mandriva
Mibbit
Mojo
Mojolicious
MSI
PerlMonks
Rakudo
SVN
TPF
Trac
Ubuntu
Ultraedit
WebGUI
Wx
wxPerl
wxPywiki
YAPC

## Padre-specific
AcmePlayCode
Autoformat
Calltips
DocBrowser
EmacsMode
Msgfmt
Nopaste
PDX
# Padre::Plugin
Plugin
# Task::Padre::Plugins
Plugins
PodFrame
TabAndSpace
WordStats

## computerese
API
Autodia
CPAN
CPANTS
cperl
DBI
DBIx
Devel
DistZilla
ExtUtils
GPL
IDE
IRC
ORDB
Packlist
PerlTidy
PPI
prepender
refactor
refactoring
Refactoring
REPL
screenshot
SQL
# svn commit
svn
urpmi
TT

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
# multi-lingual and multi-technology
multi
# July 27th
th
# perl-Padre
perl
# zh_CN
zh
CN
# Multi-platform
Multi
# padre-dev
dev

## slang
Grr

## things that should be in the dictionary, but are not
blog
bloggers
blogs
Blogs
committer
crafters
natively
oversized
screenshots
Screenshots
uncheck
uninstall
Validator
wiki

## single foreign words
hijab
kippah

## misspelt on purpose
