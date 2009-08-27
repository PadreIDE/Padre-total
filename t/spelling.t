#!perl
use 5.010;
use utf8;
use strict;
use warnings FATAL => 'all';
use autodie qw(:all);
use Capture::Tiny qw(capture);
use Encode qw(decode_utf8);
use File::Next qw();
use File::Which qw(which);
use Test::More;

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
while (defined(my $html_file = $iter->())) {
    next if $html_file =~ /translators.html \z/msx;
    $file_counter++;
    my ($stdout) = capture {
        system "aspell -H -l en list < $html_file";
    };
    my @misspelt_words = grep {!($_ ~~ @stopwords)} split /\n/, decode_utf8 $stdout;
    ok !@misspelt_words, "$html_file spell-check";
    diag join "\n", sort @misspelt_words if @misspelt_words;
}

done_testing($file_counter);

__DATA__
## personal names
Breno
Cassidy
Cezary
# Breno G. de Oliveira
de
Donelan
Fahle
Fayland
Gábor
Gábor's
garu
Jérôme
lang
Makholm
Mašláňová
Maurer
Morga
Müller
Niebur
Oliveira
Quelin
Presta
Ruslan
Shlomi
Szabó
TEEJAY
Trevena
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
refactoring
Refactoring
REPL
SQL
# svn commit
svn
urpmi
TT

## other jargon

## neologisms
cloudfiguration
hackathon
neurodiversity
screencast
technopeasant

## compound
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
uninstall
Validator
wiki

## single foreign words
Deutsch
hijab
kippah

## misspelt on purpose
